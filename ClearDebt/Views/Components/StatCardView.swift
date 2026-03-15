//
//  StatCardView.swift
//  ClearDebt
//
//  Reusable statistic display card
//

import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .accentColor
    var subtitle: String? = nil
    var trend: TrendDirection? = nil

    enum TrendDirection {
        case up, down, neutral
        var icon: String {
            switch self {
            case .up:      return "arrow.up.right"
            case .down:    return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        var color: Color {
            switch self {
            case .up:      return .green
            case .down:    return .red
            case .neutral: return .secondary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
                Spacer()
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundStyle(trend.color)
                }
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCardView(title: "Total Debt", value: "$38,350", icon: "dollarsign.circle", iconColor: .red, trend: .down)
        StatCardView(title: "Interest Saved", value: "$2,410", icon: "banknote.fill", iconColor: .green, trend: .up)
        StatCardView(title: "Months Left", value: "24", icon: "clock.fill", iconColor: .blue)
        StatCardView(title: "Progress", value: "18%", icon: "chart.bar.fill", iconColor: .purple)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
