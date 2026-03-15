//
//  PayoffPlan.swift
//  ClearDebt
//
//  SwiftData model for payoff plans and strategies
//

import Foundation
import SwiftData

// MARK: - Payoff Strategy
enum PayoffStrategy: String, Codable, CaseIterable, Identifiable {
    case avalanche  = "avalanche"   // Highest interest first
    case snowball   = "snowball"    // Lowest balance first
    case custom     = "custom"      // User-defined order

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .avalanche: return "Avalanche"
        case .snowball:  return "Snowball"
        case .custom:    return "Custom"
        }
    }

    var description: String {
        switch self {
        case .avalanche: return "Pay highest interest rate first. Saves the most money."
        case .snowball:  return "Pay smallest balance first. Builds momentum and motivation."
        case .custom:    return "Set your own payoff order based on your priorities."
        }
    }

    var icon: String {
        switch self {
        case .avalanche: return "arrow.down.forward.and.arrow.up.backward"
        case .snowball:  return "snowflake"
        case .custom:    return "slider.horizontal.3"
        }
    }

    var isPremium: Bool {
        self == .custom
    }
}

// MARK: - PayoffPlan Model
@Model
final class PayoffPlan {
    var id: UUID
    var name: String
    var strategyRaw: String   // PayoffStrategy.rawValue
    var monthlyBudget: Double
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var customOrderIDs: [String]  // Debt IDs in custom order

    var strategy: PayoffStrategy {
        PayoffStrategy(rawValue: strategyRaw) ?? .avalanche
    }

    init(
        name: String = "My Payoff Plan",
        strategy: PayoffStrategy = .avalanche,
        monthlyBudget: Double = 0,
        customOrderIDs: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.strategyRaw = strategy.rawValue
        self.monthlyBudget = monthlyBudget
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        self.customOrderIDs = customOrderIDs
    }
}

// MARK: - DebtPayoffSchedule (value type, not stored)
struct DebtPayoffSchedule: Identifiable {
    let id: UUID
    let debt: Debt
    var monthlyPayment: Double
    var payoffDate: Date
    var totalInterestPaid: Double
    var totalAmountPaid: Double
    var monthsToPayoff: Int
    var payoffOrder: Int

    var interestSaved: Double {
        let minPaySchedule = minimumPaymentSchedule(for: debt)
        return max(0, minPaySchedule.totalInterestPaid - totalInterestPaid)
    }

    private func minimumPaymentSchedule(for debt: Debt) -> DebtPayoffSchedule {
        let months = debt.monthsToPayoff(monthlyPayment: debt.minimumPayment)
        let total = debt.minimumPayment * Double(months)
        let interest = max(0, total - debt.balance)
        let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        return DebtPayoffSchedule(
            id: debt.id,
            debt: debt,
            monthlyPayment: debt.minimumPayment,
            payoffDate: date,
            totalInterestPaid: interest,
            totalAmountPaid: total,
            monthsToPayoff: months,
            payoffOrder: 0
        )
    }
}

// MARK: - PayoffProjection (value type, not stored)
struct PayoffProjection {
    var schedules: [DebtPayoffSchedule]
    var totalMonths: Int
    var totalInterestPaid: Double
    var totalAmountPaid: Double
    var debtFreeDate: Date
    var totalDebt: Double
    var totalInterestSaved: Double

    var formattedDebtFreeDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: debtFreeDate)
    }

    var monthsUntilDebtFree: Int {
        let now = Date()
        let components = Calendar.current.dateComponents([.month], from: now, to: debtFreeDate)
        return max(0, components.month ?? 0)
    }
}
