//
//  DebtListViewModel.swift
//  ClearDebt
//
//  ViewModel for managing the list of debts
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DebtListViewModel {

    // MARK: - State
    var debts: [Debt] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showAddDebt: Bool = false
    var selectedDebt: Debt?
    var searchText: String = ""
    var filterType: DebtType? = nil
    var sortOption: DebtSortOption = .balance
    var showPaidOff: Bool = false

    // MARK: - Computed
    var filteredDebts: [Debt] {
        var result = debts
        if !showPaidOff {
            result = result.filter { !$0.isPaidOff }
        }
        if let type = filterType {
            result = result.filter { $0.debtTypeEnum == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.lender.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted(by: sortOption.comparator)
    }

    var totalBalance: Double {
        debts.filter { !$0.isPaidOff }.reduce(0) { $0 + $1.balance }
    }

    var totalMinimumPayments: Double {
        debts.filter { !$0.isPaidOff }.reduce(0) { $0 + $1.minimumPayment }
    }

    var totalOriginalBalance: Double {
        debts.reduce(0) { $0 + $1.originalBalance }
    }

    var overallProgress: Double {
        guard totalOriginalBalance > 0 else { return 0 }
        let paid = totalOriginalBalance - totalBalance
        return min(1.0, max(0, paid / totalOriginalBalance))
    }

    var activeDebtCount: Int {
        debts.filter { !$0.isPaidOff }.count
    }

    var paidOffCount: Int {
        debts.filter { $0.isPaidOff }.count
    }

    var freeDebtLimit: Int { 3 }

    func canAddDebt(isPremium: Bool) -> Bool {
        isPremium || activeDebtCount < freeDebtLimit
    }

    // MARK: - CRUD

    func addDebt(_ debt: Debt, modelContext: ModelContext) {
        modelContext.insert(debt)
        do {
            try modelContext.save()
            debts.append(debt)
            AnalyticsService.shared.track(.debtAdded(type: debt.debtTypeEnum.displayName))
        } catch {
            errorMessage = "Failed to save debt: \(error.localizedDescription)"
        }
    }

    func deleteDebt(_ debt: Debt, modelContext: ModelContext) {
        modelContext.delete(debt)
        do {
            try modelContext.save()
            debts.removeAll { $0.id == debt.id }
        } catch {
            errorMessage = "Failed to delete debt: \(error.localizedDescription)"
        }
    }

    func markAsPaidOff(_ debt: Debt, modelContext: ModelContext) {
        debt.isPaidOff = true
        debt.paidOffDate = Date()
        debt.balance = 0
        debt.updatedAt = Date()
        do {
            try modelContext.save()
            AnalyticsService.shared.track(.debtPaidOff(name: debt.name))
        } catch {
            errorMessage = "Failed to update debt: \(error.localizedDescription)"
        }
    }

    func updateDebt(_ debt: Debt, modelContext: ModelContext) {
        debt.updatedAt = Date()
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update debt: \(error.localizedDescription)"
        }
    }

    func loadDebts(modelContext: ModelContext) {
        isLoading = true
        let descriptor = FetchDescriptor<Debt>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        do {
            debts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load debts: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Export

    func exportCSV() -> String {
        var csv = "Name,Type,Balance,Original Balance,Interest Rate,Minimum Payment,Due Date,Status\n"
        for debt in debts {
            let status = debt.isPaidOff ? "Paid Off" : "Active"
            csv += "\"\(debt.name)\",\"\(debt.debtTypeEnum.displayName)\",\(debt.balance),\(debt.originalBalance),\(debt.interestRate),\(debt.minimumPayment),\(debt.dueDate),\(status)\n"
        }
        return csv
    }
}

// MARK: - Sort Options
enum DebtSortOption: String, CaseIterable {
    case balance       = "Balance"
    case interestRate  = "Interest Rate"
    case name          = "Name"
    case dueDate       = "Due Date"
    case dateAdded     = "Date Added"

    var comparator: (Debt, Debt) -> Bool {
        switch self {
        case .balance:      return { $0.balance > $1.balance }
        case .interestRate: return { $0.interestRate > $1.interestRate }
        case .name:         return { $0.name < $1.name }
        case .dueDate:      return { $0.dueDate < $1.dueDate }
        case .dateAdded:    return { $0.createdAt < $1.createdAt }
        }
    }
}
