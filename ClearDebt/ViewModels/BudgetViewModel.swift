//
//  BudgetViewModel.swift
//  ClearDebt
//
//  ViewModel for monthly budget allocation and tracking
//

import Foundation
import SwiftData

@MainActor
@Observable
final class BudgetViewModel {

    // MARK: - State
    var budget: Budget?
    var monthlyIncome: Double = 0
    var extraPaymentAmount: Double = 0
    var housingExpenses: Double = 0
    var transportExpenses: Double = 0
    var foodExpenses: Double = 0
    var utilitiesExpenses: Double = 0
    var otherExpenses: Double = 0
    var isSaving: Bool = false
    var errorMessage: String?

    // MARK: - Computed

    var totalExpenses: Double {
        housingExpenses + transportExpenses + foodExpenses + utilitiesExpenses + otherExpenses
    }

    var availableForDebt: Double {
        max(0, monthlyIncome - totalExpenses)
    }

    var recommendedExtraPayment: Double {
        max(0, availableForDebt - extraPaymentAmount)
    }

    var budgetUsagePercentage: Double {
        guard monthlyIncome > 0 else { return 0 }
        return min(1.0, totalExpenses / monthlyIncome)
    }

    var debtPaymentPercentage: Double {
        guard monthlyIncome > 0 else { return 0 }
        return min(1.0, extraPaymentAmount / monthlyIncome)
    }

    var isOverBudget: Bool {
        totalExpenses + extraPaymentAmount > monthlyIncome
    }

    var expenseBreakdown: [(String, Double, String)] {
        [
            ("Housing", housingExpenses, "house.fill"),
            ("Transport", transportExpenses, "car.fill"),
            ("Food", foodExpenses, "fork.knife"),
            ("Utilities", utilitiesExpenses, "bolt.fill"),
            ("Other", otherExpenses, "ellipsis.circle.fill"),
        ]
    }

    // MARK: - Load / Save

    func loadBudget(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let existing = try? modelContext.fetch(descriptor).first {
            budget = existing
            syncFromModel(existing)
        }
    }

    func saveBudget(modelContext: ModelContext) {
        isSaving = true
        if let existing = budget {
            existing.monthlyIncome = monthlyIncome
            existing.extraPaymentAmount = extraPaymentAmount
            existing.housingExpenses = housingExpenses
            existing.transportExpenses = transportExpenses
            existing.foodExpenses = foodExpenses
            existing.utilitiesExpenses = utilitiesExpenses
            existing.otherExpenses = otherExpenses
            existing.updatedAt = Date()
        } else {
            let newBudget = Budget(
                monthlyIncome: monthlyIncome,
                extraPaymentAmount: extraPaymentAmount,
                housingExpenses: housingExpenses,
                transportExpenses: transportExpenses,
                foodExpenses: foodExpenses,
                utilitiesExpenses: utilitiesExpenses,
                otherExpenses: otherExpenses
            )
            modelContext.insert(newBudget)
            budget = newBudget
        }
        do {
            try modelContext.save()
            AnalyticsService.shared.track(.budgetUpdated)
        } catch {
            errorMessage = "Failed to save budget: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func syncFromModel(_ b: Budget) {
        monthlyIncome = b.monthlyIncome
        extraPaymentAmount = b.extraPaymentAmount
        housingExpenses = b.housingExpenses
        transportExpenses = b.transportExpenses
        foodExpenses = b.foodExpenses
        utilitiesExpenses = b.utilitiesExpenses
        otherExpenses = b.otherExpenses
    }

    // MARK: - Helpers

    func formattedCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
