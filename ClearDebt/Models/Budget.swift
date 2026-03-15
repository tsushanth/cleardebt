//
//  Budget.swift
//  ClearDebt
//
//  SwiftData model for monthly budget allocation
//

import Foundation
import SwiftData

// MARK: - Budget Model
@Model
final class Budget {
    var id: UUID
    var monthlyIncome: Double
    var extraPaymentAmount: Double   // Amount beyond minimums to apply
    var createdAt: Date
    var updatedAt: Date

    // Budget allocation
    var housingExpenses: Double
    var transportExpenses: Double
    var foodExpenses: Double
    var utilitiesExpenses: Double
    var otherExpenses: Double

    var totalExpenses: Double {
        housingExpenses + transportExpenses + foodExpenses + utilitiesExpenses + otherExpenses
    }

    var availableForDebt: Double {
        max(0, monthlyIncome - totalExpenses)
    }

    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (monthlyIncome - totalExpenses - extraPaymentAmount) / monthlyIncome
    }

    init(
        monthlyIncome: Double = 0,
        extraPaymentAmount: Double = 0,
        housingExpenses: Double = 0,
        transportExpenses: Double = 0,
        foodExpenses: Double = 0,
        utilitiesExpenses: Double = 0,
        otherExpenses: Double = 0
    ) {
        self.id = UUID()
        self.monthlyIncome = monthlyIncome
        self.extraPaymentAmount = extraPaymentAmount
        self.housingExpenses = housingExpenses
        self.transportExpenses = transportExpenses
        self.foodExpenses = foodExpenses
        self.utilitiesExpenses = utilitiesExpenses
        self.otherExpenses = otherExpenses
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Preview Helpers
extension Budget {
    static var preview: Budget {
        Budget(
            monthlyIncome: 5000,
            extraPaymentAmount: 300,
            housingExpenses: 1500,
            transportExpenses: 500,
            foodExpenses: 600,
            utilitiesExpenses: 200,
            otherExpenses: 400
        )
    }
}
