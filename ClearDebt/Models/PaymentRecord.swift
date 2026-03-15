//
//  PaymentRecord.swift
//  ClearDebt
//
//  SwiftData model for tracking individual payments
//

import Foundation
import SwiftData

// MARK: - PaymentRecord Model
@Model
final class PaymentRecord {
    var id: UUID
    var debtID: UUID
    var debtName: String
    var amount: Double
    var paymentDate: Date
    var note: String
    var isExtraPayment: Bool
    var principalPaid: Double
    var interestPaid: Double

    init(
        debtID: UUID,
        debtName: String,
        amount: Double,
        paymentDate: Date = Date(),
        note: String = "",
        isExtraPayment: Bool = false,
        principalPaid: Double = 0,
        interestPaid: Double = 0
    ) {
        self.id = UUID()
        self.debtID = debtID
        self.debtName = debtName
        self.amount = amount
        self.paymentDate = paymentDate
        self.note = note
        self.isExtraPayment = isExtraPayment
        self.principalPaid = principalPaid
        self.interestPaid = interestPaid
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: paymentDate)
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Preview Helpers
extension PaymentRecord {
    static var preview: PaymentRecord {
        PaymentRecord(
            debtID: UUID(),
            debtName: "Chase Sapphire",
            amount: 200.00,
            note: "Extra payment this month",
            isExtraPayment: true,
            principalPaid: 186.50,
            interestPaid: 13.50
        )
    }
}
