//
//  PayoffViewModel.swift
//  ClearDebt
//
//  ViewModel for payoff plan computation and display
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class PayoffViewModel {

    // MARK: - State
    var selectedStrategy: PayoffStrategy = .avalanche
    var extraMonthlyPayment: Double = 0
    var projection: PayoffProjection?
    var minimumProjection: PayoffProjection?
    var isCalculating: Bool = false
    var activeDebts: [Debt] = []
    var customOrder: [UUID] = []
    var showPaywall: Bool = false

    private let calculator = PayoffCalculator.shared

    // MARK: - Computed
    var debtFreeDate: Date? {
        projection?.debtFreeDate
    }

    var formattedDebtFreeDate: String {
        guard let date = debtFreeDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    var monthsUntilDebtFree: Int {
        projection?.monthsUntilDebtFree ?? 0
    }

    var yearsUntilDebtFree: Int {
        monthsUntilDebtFree / 12
    }

    var remainingMonths: Int {
        monthsUntilDebtFree % 12
    }

    var totalInterestPaid: Double {
        projection?.totalInterestPaid ?? 0
    }

    var totalInterestSaved: Double {
        guard let proj = projection, let minProj = minimumProjection else { return 0 }
        return max(0, minProj.totalInterestPaid - proj.totalInterestPaid)
    }

    var formattedTimeString: String {
        if yearsUntilDebtFree > 0 && remainingMonths > 0 {
            return "\(yearsUntilDebtFree)y \(remainingMonths)m"
        } else if yearsUntilDebtFree > 0 {
            return "\(yearsUntilDebtFree) year\(yearsUntilDebtFree == 1 ? "" : "s")"
        } else {
            return "\(monthsUntilDebtFree) month\(monthsUntilDebtFree == 1 ? "" : "s")"
        }
    }

    var sortedSchedules: [DebtPayoffSchedule] {
        (projection?.schedules ?? []).sorted { $0.payoffOrder < $1.payoffOrder }
    }

    // MARK: - Calculate

    func recalculate(debts: [Debt]) {
        isCalculating = true
        activeDebts = debts.filter { !$0.isPaidOff && $0.balance > 0 }

        projection = calculator.calculateProjection(
            debts: activeDebts,
            strategy: selectedStrategy,
            extraMonthlyBudget: extraMonthlyPayment,
            customOrder: customOrder
        )
        minimumProjection = calculator.minimumPaymentProjection(debts: activeDebts)
        isCalculating = false
    }

    func changeStrategy(_ strategy: PayoffStrategy, isPremium: Bool) {
        if strategy.isPremium && !isPremium {
            showPaywall = true
            return
        }
        selectedStrategy = strategy
        AnalyticsService.shared.track(.strategyChanged(strategy: strategy.rawValue))
    }

    // MARK: - Timeline Data

    struct TimelinePoint: Identifiable {
        let id = UUID()
        let month: Int
        let date: Date
        let totalBalance: Double
        let label: String?
    }

    func timelinePoints(debts: [Debt]) -> [TimelinePoint] {
        guard let proj = projection else { return [] }
        var points: [TimelinePoint] = []

        var balances = Dictionary(uniqueKeysWithValues: debts.filter { !$0.isPaidOff }.map { ($0.id, $0.balance) })
        var month = 0
        let maxMonths = min(proj.totalMonths + 1, 360)

        points.append(TimelinePoint(
            month: 0,
            date: Date(),
            totalBalance: debts.filter { !$0.isPaidOff }.reduce(0) { $0 + $1.balance },
            label: "Today"
        ))

        while month < maxMonths {
            month += 1
            // Simplified: linear interpolation per schedule
            var totalBalance = 0.0
            for schedule in proj.schedules {
                let debtBalance = balances[schedule.debt.id] ?? 0
                if debtBalance <= 0 { continue }
                let monthly = schedule.monthlyPayment
                let interest = debtBalance * schedule.debt.monthlyInterestRate
                let principal = max(0, monthly - interest)
                let newBalance = max(0, debtBalance - principal)
                balances[schedule.debt.id] = newBalance
                totalBalance += newBalance
            }

            let date = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()
            let label: String? = month == proj.totalMonths ? "Debt Free!" : nil
            points.append(TimelinePoint(month: month, date: date, totalBalance: totalBalance, label: label))
        }

        return points
    }

    // MARK: - Comparison

    struct StrategyComparison {
        let strategy: PayoffStrategy
        let months: Int
        let totalInterestPaid: Double
        let debtFreeDate: Date
        let interestSaved: Double
    }

    func strategyComparisons(debts: [Debt]) -> [StrategyComparison] {
        let minProj = calculator.minimumPaymentProjection(debts: debts)
        return [PayoffStrategy.avalanche, PayoffStrategy.snowball].map { strategy in
            let proj = calculator.calculateProjection(
                debts: debts,
                strategy: strategy,
                extraMonthlyBudget: extraMonthlyPayment
            )
            return StrategyComparison(
                strategy: strategy,
                months: proj.totalMonths,
                totalInterestPaid: proj.totalInterestPaid,
                debtFreeDate: proj.debtFreeDate,
                interestSaved: max(0, minProj.totalInterestPaid - proj.totalInterestPaid)
            )
        }
    }
}
