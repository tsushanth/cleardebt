//
//  DebtListView.swift
//  ClearDebt
//
//  Full list of debts with add, edit, delete, and filter
//

import SwiftUI
import SwiftData

struct DebtListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @Environment(PremiumManager.self) private var premiumManager

    @State private var vm = DebtListViewModel()
    @State private var showAddDebt = false
    @State private var showPaywall = false
    @State private var debtToEdit: Debt?
    @State private var sortOption: DebtSortOption = .balance
    @State private var showPaidOff = false

    var body: some View {
        NavigationStack {
            Group {
                if debts.isEmpty {
                    emptyStateView
                } else {
                    debtListContent
                }
            }
            .navigationTitle("My Debts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if vm.canAddDebt(isPremium: premiumManager.isPremium) {
                            showAddDebt = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(DebtSortOption.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        Toggle("Show Paid Off", isOn: $showPaidOff)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search debts")
            .sheet(isPresented: $showAddDebt) {
                AddDebtView(isPresented: $showAddDebt)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .sheet(item: $debtToEdit) { debt in
                AddDebtView(isPresented: .constant(true), debtToEdit: debt)
            }
            .onAppear {
                vm.loadDebts(modelContext: modelContext)
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
            Text("No Debts Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Add your debts to start planning your path to financial freedom.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showAddDebt = true
            } label: {
                Label("Add Your First Debt", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Debt List Content
    private var debtListContent: some View {
        VStack(spacing: 0) {
            // Summary banner
            summaryBanner
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Debt cards
            List {
                ForEach(filteredDebts) { debt in
                    DebtCardView(debt: debt)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture { debtToEdit = debt }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                vm.deleteDebt(debt, modelContext: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                vm.markAsPaidOff(debt, modelContext: modelContext)
                            } label: {
                                Label("Paid Off", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            }
            .listStyle(.plain)
        }
    }

    private var summaryBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(totalBalance))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(filteredDebts.count) debt\(filteredDebts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !premiumManager.isPremium {
                    Text("\(vm.activeDebtCount)/\(vm.freeDebtLimit) free")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var filteredDebts: [Debt] {
        var result = debts
        if !showPaidOff { result = result.filter { !$0.isPaidOff } }
        if !vm.searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(vm.searchText) ||
                $0.lender.localizedCaseInsensitiveContains(vm.searchText)
            }
        }
        return result.sorted(by: sortOption.comparator)
    }

    private var totalBalance: Double {
        debts.filter { !$0.isPaidOff }.reduce(0) { $0 + $1.balance }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

#Preview {
    DebtListView()
        .modelContainer(for: Debt.self, inMemory: true)
        .environment(PremiumManager())
}
