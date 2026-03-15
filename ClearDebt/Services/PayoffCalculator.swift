//
//  PayoffCalculator.swift
//  ClearDebt
//
//  Core engine for computing debt payoff schedules and projections
//

import Foundation

// MARK: - PayoffCalculator
@MainActor
final class PayoffCalculator {

    static let shared = PayoffCalculator()
    private init() {}

    // MARK: - Main Projection

    /// Computes a full payoff projection for a list of debts given a strategy and extra monthly budget.
    func calculateProjection(
        debts: [Debt],
        strategy: PayoffStrategy,
        extraMonthlyBudget: Double,
        customOrder: [UUID] = []
    ) -> PayoffProjection {
        let activeDebts = debts.filter { !$0.isPaidOff && $0.balance > 0 }
        guard !activeDebts.isEmpty else {
            return PayoffProjection(
                schedules: [],
                totalMonths: 0,
                totalInterestPaid: 0,
                totalAmountPaid: 0,
                debtFreeDate: Date(),
                totalDebt: 0,
                totalInterestSaved: 0
            )
        }

        let orderedDebts = orderDebts(activeDebts, strategy: strategy, customOrder: customOrder)
        return runAvalancheSnowballSimulation(orderedDebts: orderedDebts, extraBudget: extraMonthlyBudget)
    }

    /// Calculates projection using only minimum payments (for comparison)
    func minimumPaymentProjection(debts: [Debt]) -> PayoffProjection {
        let activeDebts = debts.filter { !$0.isPaidOff && $0.balance > 0 }
        return runAvalancheSnowballSimulation(orderedDebts: activeDebts, extraBudget: 0)
    }

    // MARK: - Debt Ordering

    private func orderDebts(_ debts: [Debt], strategy: PayoffStrategy, customOrder: [UUID]) -> [Debt] {
        switch strategy {
        case .avalanche:
            return debts.sorted { $0.interestRate > $1.interestRate }
        case .snowball:
            return debts.sorted { $0.balance < $1.balance }
        case .custom:
            if customOrder.isEmpty { return debts }
            var ordered: [Debt] = []
            for id in customOrder {
                if let debt = debts.first(where: { $0.id == id }) {
                    ordered.append(debt)
                }
            }
            // Append any debts not in custom order at the end
            let remaining = debts.filter { d in !customOrder.contains(d.id) }
            return ordered + remaining
        }
    }

    // MARK: - Simulation Engine

    private func runAvalancheSnowballSimulation(orderedDebts: [Debt], extraBudget: Double) -> PayoffProjection {
        // Copy balances as mutable state
        var balances = Dictionary(uniqueKeysWithValues: orderedDebts.map { ($0.id, $0.balance) })
        var totalInterestPaid = 0.0
        var totalAmountPaid = 0.0
        var interestPerDebt = Dictionary(uniqueKeysWithValues: orderedDebts.map { ($0.id, 0.0) })
        var amountPerDebt = Dictionary(uniqueKeysWithValues: orderedDebts.map { ($0.id, 0.0) })
        var payoffMonths = Dictionary(uniqueKeysWithValues: orderedDebts.map { ($0.id, 0) })
        var payoffDates = Dictionary(uniqueKeysWithValues: orderedDebts.map { ($0.id, Date()) })

        var month = 0
        let maxMonths = 600 // 50 years cap

        while balances.values.contains(where: { $0 > 0.001 }) && month < maxMonths {
            month += 1

            // Determine focus debt (first unpaid in order)
            let remainingDebtsInOrder = orderedDebts.filter { (balances[$0.id] ?? 0) > 0.001 }

            // Calculate freed-up minimums from paid-off debts (snowball effect)
            let paidOffMinimums = orderedDebts
                .filter { (balances[$0.id] ?? 0) <= 0.001 }
                .reduce(0.0) { $0 + $1.minimumPayment }

            var availableExtra = extraBudget + paidOffMinimums

            for (index, debt) in remainingDebtsInOrder.enumerated() {
                guard var balance = balances[debt.id], balance > 0.001 else { continue }

                let r = debt.monthlyInterestRate
                let interestThisMonth = balance * r
                totalInterestPaid += interestThisMonth
                interestPerDebt[debt.id, default: 0] += interestThisMonth

                var payment = debt.minimumPayment
                // Apply extra to focus debt (first in order)
                if index == 0 {
                    payment += availableExtra
                    availableExtra = 0
                }

                payment = min(payment, balance + interestThisMonth)
                let principal = payment - interestThisMonth
                balance -= principal
                balance = max(0, balance)

                totalAmountPaid += payment
                amountPerDebt[debt.id, default: 0] += payment
                balances[debt.id] = balance

                if balance <= 0.001 && payoffMonths[debt.id] == 0 {
                    payoffMonths[debt.id] = month
                    payoffDates[debt.id] = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()
                }
            }
        }

        // Build schedules
        var schedules: [DebtPayoffSchedule] = []
        for (index, debt) in orderedDebts.enumerated() {
            let months = payoffMonths[debt.id] ?? month
            let debtInterest = interestPerDebt[debt.id] ?? 0
            let debtAmount = amountPerDebt[debt.id] ?? 0
            let payoff = payoffDates[debt.id] ?? Date()
            let avgPayment = months > 0 ? debtAmount / Double(months) : debt.minimumPayment

            let schedule = DebtPayoffSchedule(
                id: debt.id,
                debt: debt,
                monthlyPayment: avgPayment,
                payoffDate: payoff,
                totalInterestPaid: debtInterest,
                totalAmountPaid: debtAmount,
                monthsToPayoff: months,
                payoffOrder: index + 1
            )
            schedules.append(schedule)
        }

        let debtFreeDate = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()

        // Calculate interest saved vs minimum-only
        let minProjectionInterest = orderedDebts.reduce(0.0) { sum, debt in
            let months = debt.monthsToPayoff(monthlyPayment: debt.minimumPayment)
            let total = debt.minimumPayment * Double(months)
            return sum + max(0, total - debt.balance)
        }
        let interestSaved = max(0, minProjectionInterest - totalInterestPaid)

        return PayoffProjection(
            schedules: schedules,
            totalMonths: month,
            totalInterestPaid: totalInterestPaid,
            totalAmountPaid: totalAmountPaid,
            debtFreeDate: debtFreeDate,
            totalDebt: orderedDebts.reduce(0) { $0 + $1.balance },
            totalInterestSaved: interestSaved
        )
    }

    // MARK: - Interest Saved Comparison

    func interestSavedByStrategy(debts: [Debt], extraBudget: Double) -> (avalanche: Double, snowball: Double) {
        let minProjection = minimumPaymentProjection(debts: debts)
        let avalancheProjection = calculateProjection(debts: debts, strategy: .avalanche, extraMonthlyBudget: extraBudget)
        let snowballProjection = calculateProjection(debts: debts, strategy: .snowball, extraMonthlyBudget: extraBudget)

        let avalancheSaved = max(0, minProjection.totalInterestPaid - avalancheProjection.totalInterestPaid)
        let snowballSaved = max(0, minProjection.totalInterestPaid - snowballProjection.totalInterestPaid)

        return (avalancheSaved, snowballSaved)
    }

    // MARK: - Amortization Table

    struct AmortizationRow: Identifiable {
        let id = UUID()
        let month: Int
        let date: Date
        let payment: Double
        let principal: Double
        let interest: Double
        let remainingBalance: Double
    }

    func amortizationTable(for debt: Debt, monthlyPayment: Double) -> [AmortizationRow] {
        var rows: [AmortizationRow] = []
        var balance = debt.balance
        let payment = max(monthlyPayment, debt.minimumPayment)
        var month = 0
        let maxMonths = 600

        while balance > 0.001 && month < maxMonths {
            month += 1
            let interest = balance * debt.monthlyInterestRate
            var p = payment - interest
            p = min(p, balance)
            balance -= p
            balance = max(0, balance)

            let date = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()
            rows.append(AmortizationRow(
                month: month,
                date: date,
                payment: min(payment, p + interest),
                principal: p,
                interest: interest,
                remainingBalance: balance
            ))
        }

        return rows
    }

    // MARK: - Payoff Date Estimate

    func estimatedPayoffDate(for debt: Debt, monthlyPayment: Double) -> Date {
        let months = debt.monthsToPayoff(monthlyPayment: monthlyPayment)
        return Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
    }

    // MARK: - Monthly Payment Needed

    /// Returns the monthly payment needed to pay off a debt by a target date
    func requiredMonthlyPayment(debt: Debt, byDate: Date) -> Double {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: byDate).month ?? 1
        guard months > 0 else { return debt.balance }

        let r = debt.monthlyInterestRate
        if r == 0 {
            return debt.balance / Double(months)
        }

        // PMT formula: P * r * (1+r)^n / ((1+r)^n - 1)
        let n = Double(months)
        let factor = pow(1 + r, n)
        return debt.balance * r * factor / (factor - 1)
    }
}
