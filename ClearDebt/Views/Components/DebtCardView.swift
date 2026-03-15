//
//  DebtCardView.swift
//  ClearDebt
//
//  Card view for displaying a single debt
//

import SwiftUI

struct DebtCardView: View {
    let debt: Debt

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: debt.debtTypeEnum.icon)
                        .foregroundStyle(typeColor)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(debt.name)
                        .font(.headline)
                    if !debt.lender.isEmpty {
                        Text(debt.lender)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(debt.debtTypeEnum.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(debt.balance))
                        .font(.headline)
                        .fontWeight(.bold)
                    if debt.isPaidOff {
                        Text("Paid Off")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        Text(String(format: "%.1f%% APR", debt.interestRate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            if !debt.isPaidOff {
                VStack(spacing: 4) {
                    ProgressView(value: debt.progressPercentage)
                        .tint(typeColor)
                    HStack {
                        Text(String(format: "%.0f%% paid", debt.progressPercentage * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Min: \(formatCurrency(debt.minimumPayment))/mo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Due date badge
            if !debt.isPaidOff {
                HStack {
                    Label("Due on the \(debt.dueDate)\(ordinalSuffix(debt.dueDate))", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if debt.interestRate > 0 {
                        let months = debt.monthsToPayoff(monthlyPayment: debt.minimumPayment)
                        Text(payoffTimeLabel(months))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .opacity(debt.isPaidOff ? 0.7 : 1.0)
    }

    private var typeColor: Color {
        Color(hex: debt.debtTypeEnum.colorHex) ?? .accentColor
    }

    private func formatCurrency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func ordinalSuffix(_ day: Int) -> String {
        switch day % 10 {
        case 1 where day % 100 != 11: return "st"
        case 2 where day % 100 != 12: return "nd"
        case 3 where day % 100 != 13: return "rd"
        default: return "th"
        }
    }

    private func payoffTimeLabel(_ months: Int) -> String {
        if months >= 999 { return "Interest only" }
        if months >= 12 {
            let years = months / 12
            let rem = months % 12
            if rem == 0 { return "\(years)y to payoff" }
            return "\(years)y \(rem)m to payoff"
        }
        return "\(months)m to payoff"
    }
}

// MARK: - Color from Hex
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Debt.previewList) { debt in
            DebtCardView(debt: debt)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
