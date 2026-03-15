//
//  MilestoneTracker.swift
//  ClearDebt
//
//  Evaluates and creates milestones based on debt progress
//

import Foundation
import SwiftData

@MainActor
final class MilestoneTracker {

    static let shared = MilestoneTracker()
    private init() {}

    // MARK: - Evaluate Milestones

    /// Evaluates all milestones given current debts and payments, returning any newly completed ones.
    func evaluateMilestones(
        debts: [Debt],
        payments: [PaymentRecord],
        existingMilestones: [Milestone]
    ) -> [Milestone] {
        var newMilestones: [Milestone] = []

        // First payment milestone
        if !payments.isEmpty {
            let alreadyHas = existingMilestones.contains { $0.typeRaw == MilestoneType.firstPayment.rawValue }
            if !alreadyHas {
                let m = Milestone(
                    type: .firstPayment,
                    title: "First Payment Made!",
                    description: "You made your very first debt payment. Every journey starts with a single step.",
                    targetValue: 1,
                    currentValue: 1
                )
                m.isCompleted = true
                m.completedDate = Date()
                newMilestones.append(m)
            }
        }

        // Individual debt paid off milestones
        for debt in debts where debt.isPaidOff {
            let alreadyHas = existingMilestones.contains {
                $0.typeRaw == MilestoneType.debtPaidOff.rawValue && $0.debtID == debt.id && $0.isCompleted
            }
            if !alreadyHas {
                let m = Milestone(
                    type: .debtPaidOff,
                    title: "\(debt.name) Paid Off!",
                    description: "You completely paid off your \(debt.name). Outstanding work!",
                    targetValue: debt.originalBalance,
                    currentValue: debt.originalBalance,
                    debtID: debt.id,
                    debtName: debt.name
                )
                m.isCompleted = true
                m.completedDate = debt.paidOffDate ?? Date()
                newMilestones.append(m)
            }
        }

        // Overall progress milestones: 25%, 50%, 75%
        let totalOriginal = debts.reduce(0) { $0 + $1.originalBalance }
        let totalPaid = debts.reduce(0) { $0 + ($1.originalBalance - $1.balance) }
        let overallProgress = totalOriginal > 0 ? totalPaid / totalOriginal : 0

        let checkpoints: [(Double, String, String)] = [
            (0.25, "25% Paid Off!", "You've paid off 25% of your total debt. Keep going!"),
            (0.50, "Halfway There!", "You've reached the halfway point. The finish line is getting closer!"),
            (0.75, "75% Paid Off!", "You're 75% of the way to debt freedom. Almost there!"),
        ]

        for (threshold, title, desc) in checkpoints {
            if overallProgress >= threshold {
                let alreadyHas = existingMilestones.contains {
                    $0.typeRaw == MilestoneType.percentagePaid.rawValue &&
                    $0.targetValue == threshold * 100 &&
                    $0.isCompleted
                }
                if !alreadyHas {
                    let m = Milestone(
                        type: .percentagePaid,
                        title: title,
                        description: desc,
                        targetValue: threshold * 100,
                        currentValue: overallProgress * 100
                    )
                    m.isCompleted = true
                    m.completedDate = Date()
                    newMilestones.append(m)
                }
            }
        }

        // Debt free milestone
        let allPaidOff = debts.allSatisfy { $0.isPaidOff } && !debts.isEmpty
        if allPaidOff {
            let alreadyHas = existingMilestones.contains {
                $0.typeRaw == MilestoneType.debtFree.rawValue && $0.isCompleted
            }
            if !alreadyHas {
                let m = Milestone(
                    type: .debtFree,
                    title: "DEBT FREE!",
                    description: "You did it! You are completely debt free! This is an incredible achievement!",
                    targetValue: 1,
                    currentValue: 1
                )
                m.isCompleted = true
                m.completedDate = Date()
                newMilestones.append(m)
            }
        }

        return newMilestones
    }

    // MARK: - Update Progress

    func updateMilestoneProgress(milestones: [Milestone], debts: [Debt]) {
        let totalOriginal = debts.reduce(0) { $0 + $1.originalBalance }
        let totalPaid = debts.reduce(0) { $0 + ($1.originalBalance - $1.balance) }
        let overallProgress = totalOriginal > 0 ? (totalPaid / totalOriginal) * 100 : 0

        for milestone in milestones {
            guard !milestone.isCompleted else { continue }
            switch milestone.milestoneType {
            case .percentagePaid:
                milestone.currentValue = overallProgress
                if overallProgress >= milestone.targetValue {
                    milestone.isCompleted = true
                    milestone.completedDate = Date()
                }
            case .debtFree:
                let allPaidOff = debts.allSatisfy { $0.isPaidOff } && !debts.isEmpty
                if allPaidOff {
                    milestone.currentValue = 1
                    milestone.isCompleted = true
                    milestone.completedDate = Date()
                }
            default:
                break
            }
        }
    }

    // MARK: - Generate Default Milestones

    func generateDefaultMilestones(for debts: [Debt]) -> [Milestone] {
        var milestones: [Milestone] = []

        // Add 25%, 50%, 75% overall milestones
        let progressMilestones: [(Double, String, String)] = [
            (25, "25% Paid Off!", "Pay off 25% of your total debt."),
            (50, "Halfway There!", "Reach the halfway point of your debt journey."),
            (75, "75% Paid Off!", "Pay off 75% of your total debt."),
        ]
        for (pct, title, desc) in progressMilestones {
            milestones.append(Milestone(type: .percentagePaid, title: title, description: desc, targetValue: pct))
        }

        // Debt free
        milestones.append(Milestone(type: .debtFree, title: "Debt Free!", description: "Pay off all your debts completely.", targetValue: 1))

        // Individual debt milestones
        for debt in debts {
            milestones.append(Milestone(
                type: .debtPaidOff,
                title: "\(debt.name) Paid Off!",
                description: "Pay off your \(debt.name) completely.",
                targetValue: debt.balance,
                debtID: debt.id,
                debtName: debt.name
            ))
        }

        return milestones
    }
}
