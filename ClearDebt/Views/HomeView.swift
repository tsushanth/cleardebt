//
//  HomeView.swift
//  ClearDebt
//
//  Main dashboard showing debt summary, countdown, and quick stats
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @Query private var milestones: [Milestone]
    @Environment(PremiumManager.self) private var premiumManager

    @State private var debtListVM = DebtListViewModel()
    @State private var payoffVM = PayoffViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header greeting
                    headerSection

                    // Debt-free countdown card
                    countdownCard

                    // Summary stats
                    statsGrid

                    // Recent milestones
                    if !completedMilestones.isEmpty {
                        milestonesSection
                    }

                    // Quick actions
                    quickActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ClearDebt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                debtListVM.loadDebts(modelContext: modelContext)
                payoffVM.recalculate(debts: debts.filter { !$0.isPaidOff })
            }
            .onChange(of: debts.count) { _, _ in
                payoffVM.recalculate(debts: debts.filter { !$0.isPaidOff })
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Your debt journey")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            if premiumManager.isPremium {
                Label("Premium", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Countdown Card
    private var countdownCard: some View {
        VStack(spacing: 12) {
            if activeDebts.isEmpty {
                emptyStateCard
            } else {
                VStack(spacing: 8) {
                    Text("Debt-Free in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(payoffVM.formattedTimeString)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                    Text(payoffVM.formattedDebtFreeDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider().padding(.vertical, 4)

                    HStack(spacing: 24) {
                        statPill(title: "Total Debt", value: formatCurrency(totalBalance))
                        statPill(title: "Interest Saved", value: formatCurrency(payoffVM.totalInterestSaved))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("Add your first debt to get started")
                .font(.headline)
            Text("Track your balances and build a payoff plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Active Debts", value: "\(activeDebts.count)", icon: "list.bullet", color: .blue)
            statCard(title: "Paid Off", value: "\(paidOffCount)", icon: "checkmark.circle.fill", color: .green)
            statCard(title: "Monthly Minimums", value: formatCurrency(totalMinimums), icon: "calendar", color: .orange)
            statCard(title: "Overall Progress", value: String(format: "%.0f%%", overallProgress * 100), icon: "chart.bar.fill", color: .purple)
        }
    }

    // MARK: - Milestones Section
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Milestones")
                .font(.headline)
            ForEach(completedMilestones.prefix(3)) { milestone in
                MilestoneRowView(milestone: milestone)
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            HStack(spacing: 12) {
                quickActionButton(title: "View Plan", icon: "chart.line.uptrend.xyaxis", color: .blue) {
                    // Navigation handled by tab bar
                }
                quickActionButton(title: "Add Payment", icon: "plus.circle.fill", color: .green) {
                    // TODO: navigate to log payment
                }
            }
        }
    }

    // MARK: - Helpers

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var activeDebts: [Debt] { debts.filter { !$0.isPaidOff } }
    private var paidOffCount: Int { debts.filter { $0.isPaidOff }.count }
    private var totalBalance: Double { activeDebts.reduce(0) { $0 + $1.balance } }
    private var totalMinimums: Double { activeDebts.reduce(0) { $0 + $1.minimumPayment } }
    private var totalOriginal: Double { debts.reduce(0) { $0 + $1.originalBalance } }
    private var overallProgress: Double {
        guard totalOriginal > 0 else { return 0 }
        return min(1.0, (totalOriginal - totalBalance) / totalOriginal)
    }
    private var completedMilestones: [Milestone] {
        milestones.filter { $0.isCompleted }.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Debt.self, Milestone.self], inMemory: true)
        .environment(PremiumManager())
}
