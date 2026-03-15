//
//  BudgetView.swift
//  ClearDebt
//
//  Monthly budget planning and allocation view
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = BudgetViewModel()
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget overview card
                    budgetOverviewCard

                    // Expense breakdown
                    expenseBreakdownSection

                    // Extra payment allocation
                    extraPaymentCard

                    // Recommendations
                    if vm.monthlyIncome > 0 {
                        recommendationsCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            vm.saveBudget(modelContext: modelContext)
                        }
                        isEditing.toggle()
                    }
                    .fontWeight(isEditing ? .semibold : .regular)
                }
            }
            .onAppear {
                vm.loadBudget(modelContext: modelContext)
            }
        }
    }

    // MARK: - Budget Overview
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                budgetStat(title: "Monthly Income", value: vm.formattedCurrency(vm.monthlyIncome), color: .green)
                Divider().frame(height: 50)
                budgetStat(title: "Expenses", value: vm.formattedCurrency(vm.totalExpenses), color: .red)
                Divider().frame(height: 50)
                budgetStat(title: "Available", value: vm.formattedCurrency(vm.availableForDebt), color: .blue)
            }

            if isEditing {
                HStack {
                    Text("Monthly Income")
                    Spacer()
                    TextField("$0", value: $vm.monthlyIncome, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Usage bar
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.isOverBudget ? "Over Budget!" : "Budget Usage")
                    .font(.caption)
                    .foregroundStyle(vm.isOverBudget ? .red : .secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(vm.isOverBudget ? Color.red : Color.accentColor)
                            .frame(width: geo.size.width * min(1.0, vm.budgetUsagePercentage))
                    }
                }
                .frame(height: 8)
                HStack {
                    Text(String(format: "%.0f%% of income used", vm.budgetUsagePercentage * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Expense Breakdown
    private var expenseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Expenses")
                .font(.headline)
            ForEach(expenseItems, id: \.title) { item in
                expenseRow(item: item)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    struct ExpenseItem {
        let title: String
        let icon: String
        let binding: Binding<Double>
        let color: Color
    }

    private var expenseItems: [ExpenseItem] {
        [
            ExpenseItem(title: "Housing", icon: "house.fill", binding: $vm.housingExpenses, color: .blue),
            ExpenseItem(title: "Transport", icon: "car.fill", binding: $vm.transportExpenses, color: .orange),
            ExpenseItem(title: "Food", icon: "fork.knife", binding: $vm.foodExpenses, color: .green),
            ExpenseItem(title: "Utilities", icon: "bolt.fill", binding: $vm.utilitiesExpenses, color: .yellow),
            ExpenseItem(title: "Other", icon: "ellipsis.circle.fill", binding: $vm.otherExpenses, color: .purple),
        ]
    }

    private func expenseRow(item: ExpenseItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
                .frame(width: 24)
            Text(item.title)
                .font(.subheadline)
            Spacer()
            if isEditing {
                TextField("$0", value: item.binding, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(vm.formattedCurrency(item.binding.wrappedValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Extra Payment Card
    private var extraPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Extra Debt Payment", systemImage: "arrow.up.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            Text("Amount beyond minimum payments applied to accelerate payoff.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isEditing {
                HStack {
                    Text("Extra Payment")
                    Spacer()
                    TextField("$0", value: $vm.extraPaymentAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                HStack {
                    Text(vm.formattedCurrency(vm.extraPaymentAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    if vm.recommendedExtraPayment > 0 {
                        Text("Up to \(vm.formattedCurrency(vm.recommendedExtraPayment)) available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Recommendations
    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.yellow)

            if vm.isOverBudget {
                recommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    text: "Your expenses exceed your income. Consider reducing discretionary spending."
                )
            } else if vm.recommendedExtraPayment > 0 {
                recommendationRow(
                    icon: "arrow.up.circle.fill",
                    color: .green,
                    text: "You have \(vm.formattedCurrency(vm.recommendedExtraPayment)) available to put toward extra debt payments."
                )
            } else {
                recommendationRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Great! Your budget is well-balanced."
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func recommendationRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers
    private func budgetStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: Budget.self, inMemory: true)
}
