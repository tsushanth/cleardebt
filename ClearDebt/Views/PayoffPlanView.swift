//
//  PayoffPlanView.swift
//  ClearDebt
//
//  Payoff strategy selector and plan overview
//

import SwiftUI
import SwiftData

struct PayoffPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @Environment(PremiumManager.self) private var premiumManager

    @State private var vm = PayoffViewModel()
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Strategy selector
                    strategySelector

                    // Extra payment slider
                    extraPaymentSection

                    // Projection summary card
                    if let projection = vm.projection, !projection.schedules.isEmpty {
                        projectionSummary(projection)

                        // Payoff order list
                        payoffOrderSection(projection)
                    } else {
                        emptyPlanCard
                    }

                    // Strategy comparison
                    if !debts.filter({ !$0.isPaidOff }).isEmpty {
                        strategyComparisonSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Payoff Plan")
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .onAppear {
                vm.recalculate(debts: debts)
            }
            .onChange(of: debts.count) { _, _ in vm.recalculate(debts: debts) }
            .onChange(of: vm.selectedStrategy) { _, _ in vm.recalculate(debts: debts) }
            .onChange(of: vm.extraMonthlyPayment) { _, _ in vm.recalculate(debts: debts) }
        }
    }

    // MARK: - Strategy Selector
    private var strategySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy")
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(PayoffStrategy.allCases) { strategy in
                    strategyButton(strategy)
                }
            }
        }
    }

    private func strategyButton(_ strategy: PayoffStrategy) -> some View {
        Button {
            vm.changeStrategy(strategy, isPremium: premiumManager.isPremium)
            if !strategy.isPremium || premiumManager.isPremium {
                vm.recalculate(debts: debts)
            } else {
                showPaywall = true
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: strategy.icon)
                        .font(.title3)
                    if strategy.isPremium && !premiumManager.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .offset(x: 12, y: -8)
                    }
                }
                Text(strategy.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(vm.selectedStrategy == strategy ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            )
            .foregroundStyle(vm.selectedStrategy == strategy ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Extra Payment
    private var extraPaymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Extra Monthly Payment")
                    .font(.headline)
                Spacer()
                Text(formatCurrency(vm.extraMonthlyPayment))
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
            Slider(value: $vm.extraMonthlyPayment, in: 0...2000, step: 25)
                .tint(Color.accentColor)
            HStack {
                Text("$0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("$2,000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Projection Summary
    private func projectionSummary(_ proj: PayoffProjection) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Payoff Plan")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: PayoffTimelineView()) {
                    Label("Timeline", systemImage: "chart.xyaxis.line")
                        .font(.caption)
                }
            }
            HStack(spacing: 0) {
                projStat(title: "Debt Free", value: vm.formattedDebtFreeDate, icon: "flag.fill", color: .green)
                Divider().frame(height: 50)
                projStat(title: "Time", value: vm.formattedTimeString, icon: "clock.fill", color: .blue)
                Divider().frame(height: 50)
                projStat(title: "Interest Saved", value: formatCurrency(vm.totalInterestSaved), icon: "banknote.fill", color: .orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func projStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Payoff Order
    private func payoffOrderSection(_ proj: PayoffProjection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payoff Order")
                .font(.headline)
            ForEach(vm.sortedSchedules) { schedule in
                payoffScheduleRow(schedule)
            }
        }
    }

    private func payoffScheduleRow(_ schedule: DebtPayoffSchedule) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(schedule.payoffOrder)")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.debt.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(payoffDateLabel(schedule.payoffDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(schedule.monthlyPayment))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("/month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Strategy Comparison
    private var strategyComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Comparison")
                .font(.headline)
            ForEach(vm.strategyComparisons(debts: debts), id: \.strategy) { comparison in
                HStack {
                    Label(comparison.strategy.displayName, systemImage: comparison.strategy.icon)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(comparison.interestSaved) + " saved")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        Text("\(comparison.months) months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    // MARK: - Empty State
    private var emptyPlanCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Add debts to see your payoff plan")
                .font(.headline)
            Text("Your personalized schedule will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Helpers
    private func payoffDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Paid off: \(formatter.string(from: date))"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

#Preview {
    PayoffPlanView()
        .modelContainer(for: Debt.self, inMemory: true)
        .environment(PremiumManager())
}
