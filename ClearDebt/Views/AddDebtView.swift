//
//  AddDebtView.swift
//  ClearDebt
//
//  Form for adding or editing a debt
//

import SwiftUI
import SwiftData

struct AddDebtView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var debtToEdit: Debt? = nil

    // Form fields
    @State private var name: String = ""
    @State private var debtType: DebtType = .creditCard
    @State private var balance: String = ""
    @State private var originalBalance: String = ""
    @State private var interestRate: String = ""
    @State private var minimumPayment: String = ""
    @State private var dueDate: Int = 1
    @State private var lender: String = ""
    @State private var notes: String = ""
    @State private var isSameAsBalance: Bool = true

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool { debtToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Debt Name (e.g. Chase Sapphire)", text: $name)
                    Picker("Type", selection: $debtType) {
                        ForEach(DebtType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    TextField("Lender / Institution", text: $lender)
                } header: {
                    Text("Debt Info")
                }

                // Balances
                Section {
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        TextField("$0.00", text: $balance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.accentColor)
                    }
                    Toggle("Original balance same as current", isOn: $isSameAsBalance)
                    if !isSameAsBalance {
                        HStack {
                            Text("Original Balance")
                            Spacer()
                            TextField("$0.00", text: $originalBalance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text("Balance")
                }

                // Payment Details
                Section {
                    HStack {
                        Text("Annual Interest Rate (%)")
                        Spacer()
                        TextField("0.00", text: $interestRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Minimum Payment")
                        Spacer()
                        TextField("$0.00", text: $minimumPayment)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Stepper("Due Day: \(dueDate)", value: $dueDate, in: 1...31)
                } header: {
                    Text("Payment Details")
                }

                // Notes
                Section {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Debt" : "Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveDebt()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Please fix the following", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                if let debt = debtToEdit {
                    name = debt.name
                    debtType = debt.debtTypeEnum
                    balance = String(format: "%.2f", debt.balance)
                    interestRate = String(format: "%.2f", debt.interestRate)
                    minimumPayment = String(format: "%.2f", debt.minimumPayment)
                    dueDate = debt.dueDate
                    lender = debt.lender
                    notes = debt.notes
                    if debt.originalBalance != debt.balance {
                        isSameAsBalance = false
                        originalBalance = String(format: "%.2f", debt.originalBalance)
                    }
                }
            }
        }
    }

    private func saveDebt() {
        guard validate() else { return }

        let bal = Double(balance) ?? 0
        let rate = Double(interestRate) ?? 0
        let minPay = Double(minimumPayment) ?? 0
        let origBal = isSameAsBalance ? bal : (Double(originalBalance) ?? bal)

        if let debt = debtToEdit {
            debt.name = name
            debt.debtType = debtType.rawValue
            debt.balance = bal
            debt.interestRate = rate
            debt.minimumPayment = minPay
            debt.dueDate = dueDate
            debt.lender = lender
            debt.notes = notes
            debt.originalBalance = origBal
            debt.updatedAt = Date()
            try? modelContext.save()
        } else {
            let newDebt = Debt(
                name: name,
                debtType: debtType,
                balance: bal,
                interestRate: rate,
                minimumPayment: minPay,
                dueDate: dueDate,
                notes: notes,
                lender: lender,
                originalBalance: origBal
            )
            modelContext.insert(newDebt)
            try? modelContext.save()
            AnalyticsService.shared.track(.debtAdded(type: debtType.displayName))
        }

        isPresented = false
    }

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a debt name."
            showValidationError = true
            return false
        }
        guard let bal = Double(balance), bal >= 0 else {
            validationMessage = "Please enter a valid balance."
            showValidationError = true
            return false
        }
        guard let rate = Double(interestRate), rate >= 0 else {
            validationMessage = "Please enter a valid interest rate."
            showValidationError = true
            return false
        }
        guard let minPay = Double(minimumPayment), minPay >= 0 else {
            validationMessage = "Please enter a valid minimum payment."
            showValidationError = true
            return false
        }
        _ = bal; _ = rate; _ = minPay
        return true
    }
}

#Preview {
    AddDebtView(isPresented: .constant(true))
        .modelContainer(for: Debt.self, inMemory: true)
}
