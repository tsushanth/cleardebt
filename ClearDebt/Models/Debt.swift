//
//  Debt.swift
//  ClearDebt
//
//  SwiftData model for individual debts
//

import Foundation
import SwiftData

// MARK: - Debt Type
enum DebtType: String, Codable, CaseIterable, Identifiable {
    case creditCard     = "credit_card"
    case personalLoan   = "personal_loan"
    case autoLoan       = "auto_loan"
    case studentLoan    = "student_loan"
    case mortgage       = "mortgage"
    case medicalDebt    = "medical_debt"
    case other          = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creditCard:   return "Credit Card"
        case .personalLoan: return "Personal Loan"
        case .autoLoan:     return "Auto Loan"
        case .studentLoan:  return "Student Loan"
        case .mortgage:     return "Mortgage"
        case .medicalDebt:  return "Medical Debt"
        case .other:        return "Other"
        }
    }

    var icon: String {
        switch self {
        case .creditCard:   return "creditcard.fill"
        case .personalLoan: return "person.text.rectangle.fill"
        case .autoLoan:     return "car.fill"
        case .studentLoan:  return "graduationcap.fill"
        case .mortgage:     return "house.fill"
        case .medicalDebt:  return "cross.case.fill"
        case .other:        return "dollarsign.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .creditCard:   return "#FF6B6B"
        case .personalLoan: return "#4ECDC4"
        case .autoLoan:     return "#45B7D1"
        case .studentLoan:  return "#96CEB4"
        case .mortgage:     return "#FFEAA7"
        case .medicalDebt:  return "#DDA0DD"
        case .other:        return "#98FB98"
        }
    }
}

// MARK: - Debt Model
@Model
final class Debt {
    var id: UUID
    var name: String
    var debtType: String  // DebtType.rawValue
    var balance: Double
    var interestRate: Double   // Annual percentage rate
    var minimumPayment: Double
    var dueDate: Int           // Day of month (1-31)
    var createdAt: Date
    var updatedAt: Date
    var notes: String
    var isPaidOff: Bool
    var paidOffDate: Date?
    var originalBalance: Double
    var lender: String

    // Computed: not stored
    var debtTypeEnum: DebtType {
        DebtType(rawValue: debtType) ?? .other
    }

    var monthlyInterestRate: Double {
        interestRate / 100.0 / 12.0
    }

    var totalInterestRemaining: Double {
        guard monthlyInterestRate > 0 else { return 0 }
        let n = monthsToPayoff(monthlyPayment: minimumPayment)
        let total = minimumPayment * Double(n)
        return max(0, total - balance)
    }

    var progressPercentage: Double {
        guard originalBalance > 0 else { return 0 }
        let paid = originalBalance - balance
        return min(1.0, max(0.0, paid / originalBalance))
    }

    init(
        name: String,
        debtType: DebtType = .creditCard,
        balance: Double,
        interestRate: Double,
        minimumPayment: Double,
        dueDate: Int = 1,
        notes: String = "",
        lender: String = "",
        originalBalance: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.debtType = debtType.rawValue
        self.balance = balance
        self.interestRate = interestRate
        self.minimumPayment = minimumPayment
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
        self.isPaidOff = false
        self.paidOffDate = nil
        self.originalBalance = originalBalance ?? balance
        self.lender = lender
    }

    func monthsToPayoff(monthlyPayment: Double) -> Int {
        guard balance > 0 else { return 0 }
        let payment = max(monthlyPayment, minimumPayment)

        if monthlyInterestRate == 0 {
            return Int(ceil(balance / payment))
        }

        let r = monthlyInterestRate
        let b = balance
        let p = payment

        // n = -log(1 - r*b/p) / log(1+r)
        guard r * b < p else { return 999 } // Would never pay off
        let n = -log(1 - r * b / p) / log(1 + r)
        return Int(ceil(n))
    }

    func interestSavedWithExtraPayment(_ extra: Double) -> Double {
        let baseMonths = monthsToPayoff(monthlyPayment: minimumPayment)
        let acceleratedMonths = monthsToPayoff(monthlyPayment: minimumPayment + extra)

        let baseTotalPaid = minimumPayment * Double(baseMonths)
        let acceleratedTotalPaid = (minimumPayment + extra) * Double(acceleratedMonths)

        let baseInterest = max(0, baseTotalPaid - balance)
        let acceleratedInterest = max(0, acceleratedTotalPaid - balance)

        return max(0, baseInterest - acceleratedInterest)
    }
}

// MARK: - Preview Helpers
extension Debt {
    static var preview: Debt {
        Debt(
            name: "Chase Sapphire",
            debtType: .creditCard,
            balance: 4500.00,
            interestRate: 19.99,
            minimumPayment: 135.00,
            dueDate: 15,
            lender: "Chase Bank",
            originalBalance: 5000.00
        )
    }

    static var previewList: [Debt] {
        [
            Debt(name: "Chase Sapphire", debtType: .creditCard, balance: 4500, interestRate: 19.99, minimumPayment: 135, dueDate: 15, lender: "Chase", originalBalance: 5000),
            Debt(name: "Car Loan", debtType: .autoLoan, balance: 12000, interestRate: 6.5, minimumPayment: 320, dueDate: 5, lender: "Toyota Financial", originalBalance: 18000),
            Debt(name: "Student Loan", debtType: .studentLoan, balance: 22000, interestRate: 4.5, minimumPayment: 230, dueDate: 20, lender: "Navient", originalBalance: 28000),
            Debt(name: "Medical Bill", debtType: .medicalDebt, balance: 850, interestRate: 0, minimumPayment: 50, dueDate: 10, lender: "City Hospital", originalBalance: 1200),
        ]
    }
}
