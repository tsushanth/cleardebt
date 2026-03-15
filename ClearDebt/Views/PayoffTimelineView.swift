//
//  PayoffTimelineView.swift
//  ClearDebt
//
//  Visual timeline chart showing balance reduction over time
//

import SwiftUI
import SwiftData
import Charts

struct PayoffTimelineView: View {
    @Query private var debts: [Debt]
    @State private var vm = PayoffViewModel()
    @State private var selectedStrategy: PayoffStrategy = .avalanche
    @State private var extraPayment: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Strategy picker
                Picker("Strategy", selection: $selectedStrategy) {
                    ForEach(PayoffStrategy.allCases.filter { !$0.isPremium }) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Balance chart
                chartSection

                // Key dates list
                keyDatesSection

                // Amortization note
                interestSummary
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { recalculate() }
        .onChange(of: selectedStrategy) { _, _ in recalculate() }
        .onChange(of: extraPayment) { _, _ in recalculate() }
    }

    // MARK: - Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Over Time")
                .font(.headline)
                .padding(.horizontal, 16)

            let points = vm.timelinePoints(debts: debts.filter { !$0.isPaidOff })

            if points.isEmpty {
                Text("No data to display")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        y: .value("Balance", point.totalBalance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Balance", point.totalBalance)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    if let label = point.label {
                        PointMark(
                            x: .value("Month", point.month),
                            y: .value("Balance", point.totalBalance)
                        )
                        .annotation(position: .top) {
                            Text(label)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 12)) { value in
                        AxisValueLabel {
                            if let month = value.as(Int.self) {
                                Text("Y\(month / 12)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(shortCurrency(amount))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Key Dates
    private var keyDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payoff Dates")
                .font(.headline)

            ForEach(vm.sortedSchedules) { schedule in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(schedule.debt.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(schedule.debt.debtTypeEnum.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(payoffDateLabel(schedule.payoffDate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(schedule.monthsToPayoff) months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Interest Summary
    private var interestSummary: some View {
        HStack(spacing: 16) {
            summaryTile(
                title: "Total Interest",
                value: formatCurrency(vm.projection?.totalInterestPaid ?? 0),
                icon: "percent",
                color: .red
            )
            summaryTile(
                title: "Total Paid",
                value: formatCurrency(vm.projection?.totalAmountPaid ?? 0),
                icon: "dollarsign.circle",
                color: .green
            )
        }
        .padding(.horizontal, 16)
    }

    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Helpers
    private func recalculate() {
        vm.selectedStrategy = selectedStrategy
        vm.extraMonthlyPayment = extraPayment
        vm.recalculate(debts: debts)
    }

    private func payoffDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func shortCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.0fk", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }
}

#Preview {
    NavigationStack {
        PayoffTimelineView()
            .modelContainer(for: Debt.self, inMemory: true)
    }
}
