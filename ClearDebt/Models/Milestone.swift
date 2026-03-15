//
//  Milestone.swift
//  ClearDebt
//
//  SwiftData model for motivational milestones and achievements
//

import Foundation
import SwiftData

// MARK: - MilestoneType
enum MilestoneType: String, Codable, CaseIterable {
    case debtPaidOff        = "debt_paid_off"
    case percentagePaid     = "percentage_paid"
    case totalSaved         = "total_saved"
    case paymentStreak      = "payment_streak"
    case debtFree           = "debt_free"
    case firstPayment       = "first_payment"
    case halfwayThere       = "halfway_there"

    var icon: String {
        switch self {
        case .debtPaidOff:     return "checkmark.seal.fill"
        case .percentagePaid:  return "percent"
        case .totalSaved:      return "banknote.fill"
        case .paymentStreak:   return "flame.fill"
        case .debtFree:        return "star.fill"
        case .firstPayment:    return "1.circle.fill"
        case .halfwayThere:    return "flag.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .debtPaidOff:     return "#4CAF50"
        case .percentagePaid:  return "#2196F3"
        case .totalSaved:      return "#FF9800"
        case .paymentStreak:   return "#F44336"
        case .debtFree:        return "#9C27B0"
        case .firstPayment:    return "#00BCD4"
        case .halfwayThere:    return "#FF5722"
        }
    }
}

// MARK: - Milestone Model
@Model
final class Milestone {
    var id: UUID
    var typeRaw: String   // MilestoneType.rawValue
    var title: String
    var milestoneDescription: String
    var targetValue: Double
    var currentValue: Double
    var isCompleted: Bool
    var completedDate: Date?
    var createdAt: Date
    var debtID: UUID?      // nil = overall goal
    var debtName: String

    var milestoneType: MilestoneType {
        MilestoneType(rawValue: typeRaw) ?? .percentagePaid
    }

    var progress: Double {
        guard targetValue > 0 else { return isCompleted ? 1.0 : 0.0 }
        return min(1.0, currentValue / targetValue)
    }

    init(
        type: MilestoneType,
        title: String,
        description: String,
        targetValue: Double,
        currentValue: Double = 0,
        debtID: UUID? = nil,
        debtName: String = ""
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.title = title
        self.milestoneDescription = description
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isCompleted = false
        self.completedDate = nil
        self.createdAt = Date()
        self.debtID = debtID
        self.debtName = debtName
    }
}

// MARK: - Preview Helpers
extension Milestone {
    static var preview: Milestone {
        Milestone(
            type: .percentagePaid,
            title: "25% Paid Off!",
            description: "You've paid off 25% of your Chase Sapphire balance.",
            targetValue: 1250,
            currentValue: 1250,
            debtName: "Chase Sapphire"
        )
    }

    static var previewList: [Milestone] {
        [
            Milestone(type: .firstPayment, title: "First Payment Made!", description: "You made your first payment. Great start!", targetValue: 1, currentValue: 1, debtName: ""),
            Milestone(type: .percentagePaid, title: "25% Paid Off", description: "One quarter of the way there!", targetValue: 100, currentValue: 25, debtName: "Chase Sapphire"),
            Milestone(type: .halfwayThere, title: "Halfway There!", description: "You've paid off half your total debt!", targetValue: 100, currentValue: 50, debtName: ""),
            Milestone(type: .debtFree, title: "Debt Free!", description: "You paid off all your debt!", targetValue: 1, currentValue: 0, debtName: ""),
        ]
    }
}
