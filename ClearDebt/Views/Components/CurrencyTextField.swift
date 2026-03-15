//
//  CurrencyTextField.swift
//  ClearDebt
//
//  Reusable currency input field
//

import SwiftUI

struct CurrencyTextField: View {
    let title: String
    @Binding var value: Double
    var placeholder: String = "0.00"

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 2) {
                Text(currencySymbol)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .onChange(of: text) { _, newVal in
                        let cleaned = newVal.filter { $0.isNumber || $0 == "." }
                        if let d = Double(cleaned) {
                            value = d
                        } else if cleaned.isEmpty {
                            value = 0
                        }
                    }
                    .onAppear {
                        text = value > 0 ? String(format: "%.2f", value) : ""
                    }
            }
            .foregroundStyle(Color.accentColor)
        }
    }

    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
}

#Preview {
    Form {
        CurrencyTextField(title: "Balance", value: .constant(1234.56))
    }
}
