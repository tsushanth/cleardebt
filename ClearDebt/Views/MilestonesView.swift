//
//  MilestonesView.swift
//  ClearDebt
//
//  Achievements and motivational milestones tracker
//

import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query private var milestones: [Milestone]
    @Query private var debts: [Debt]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress overview
                    progressOverview

                    // Completed milestones
                    if !completedMilestones.isEmpty {
                        milestoneSection(title: "Achievements Unlocked", milestones: completedMilestones, isCompleted: true)
                    }

                    // Upcoming milestones
                    if !upcomingMilestones.isEmpty {
                        milestoneSection(title: "Coming Up", milestones: upcomingMilestones, isCompleted: false)
                    }

                    if milestones.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Milestones")
        }
    }

    // MARK: - Progress Overview
    private var progressOverview: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completedMilestones.count) of \(milestones.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Milestones Achieved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: completionRatio)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.0f%%", completionRatio * 100))
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }

            ProgressView(value: completionRatio)
                .tint(Color.accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Milestone Section
    private func milestoneSection(title: String, milestones: [Milestone], isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            ForEach(milestones) { milestone in
                MilestoneRowView(milestone: milestone)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
            Text("No milestones yet")
                .font(.headline)
            Text("Add debts and start making payments to unlock achievements.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Computed
    private var completedMilestones: [Milestone] {
        milestones
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    private var upcomingMilestones: [Milestone] {
        milestones
            .filter { !$0.isCompleted }
            .sorted { $0.progress > $1.progress }
    }

    private var completionRatio: Double {
        guard !milestones.isEmpty else { return 0 }
        return Double(completedMilestones.count) / Double(milestones.count)
    }
}

// MARK: - Milestone Row
struct MilestoneRowView: View {
    let milestone: Milestone

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(milestone.isCompleted ? accentColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 44, height: 44)
                Image(systemName: milestone.milestoneType.icon)
                    .font(.title3)
                    .foregroundStyle(milestone.isCompleted ? accentColor : .secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(milestone.isCompleted ? .primary : .secondary)
                if milestone.isCompleted, let date = milestone.completedDate {
                    Text(completedDateLabel(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView(value: milestone.progress)
                        .tint(accentColor)
                        .frame(maxWidth: 160)
                }
            }
            Spacer()
            if milestone.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var accentColor: Color { Color.accentColor }

    private func completedDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

#Preview {
    MilestonesView()
        .modelContainer(for: [Milestone.self, Debt.self], inMemory: true)
}
