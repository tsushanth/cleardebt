//
//  ProgressRingView.swift
//  ClearDebt
//
//  Circular progress ring component
//

import SwiftUI

struct ProgressRingView: View {
    let progress: Double  // 0.0 to 1.0
    var lineWidth: CGFloat = 10
    var size: CGFloat = 80
    var color: Color = .accentColor
    var showLabel: Bool = true
    var label: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
            if showLabel {
                Text(label ?? String(format: "%.0f%%", progress * 100))
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressRingView(progress: 0.35, color: .blue)
        ProgressRingView(progress: 0.65, color: .green)
        ProgressRingView(progress: 0.90, color: .orange, label: "90%")
    }
    .padding()
}
