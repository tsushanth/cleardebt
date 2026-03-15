//
//  OnboardingView.swift
//  ClearDebt
//
//  First-launch onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showNotificationPrompt = false
    @Environment(PremiumManager.self) private var premiumManager

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "dollarsign.circle.fill",
            iconColor: .accentColor,
            title: "Take Control of\nYour Debt",
            description: "ClearDebt helps you build a personalized payoff plan and track your progress toward financial freedom.",
            badge: nil
        ),
        OnboardingPage(
            icon: "chart.line.downtrend.xyaxis",
            iconColor: .green,
            title: "Avalanche or\nSnowball?",
            description: "Choose the strategy that fits your goals. Avalanche saves the most interest. Snowball builds momentum. We handle the math.",
            badge: nil
        ),
        OnboardingPage(
            icon: "flag.checkered",
            iconColor: .orange,
            title: "Celebrate Every\nMilestone",
            description: "Stay motivated with achievement badges, a debt-free countdown, and interest saved tracking.",
            badge: nil
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: .red,
            title: "Never Miss a\nPayment",
            description: "Set payment reminders so you always pay on time and avoid extra fees.",
            badge: "Optional"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.accentColor : Color(.systemGray4))
                        .frame(width: i == currentPage ? 20 : 8, height: 8)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // Bottom buttons
            VStack(spacing: 12) {
                Button {
                    advancePage()
                } label: {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        complete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showNotificationPrompt) {
            notificationSheet
        }
    }

    private var notificationSheet: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
            Text("Enable Payment Reminders?")
                .font(.title2)
                .fontWeight(.bold)
            Text("We'll remind you a few days before each debt payment is due.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Allow Notifications") {
                Task {
                    await NotificationManager.shared.requestAuthorization()
                    showNotificationPrompt = false
                    complete()
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 32)

            Button("Not Now") {
                showNotificationPrompt = false
                complete()
            }
            .foregroundStyle(.secondary)
            Spacer()
        }
        .presentationDetents([.medium])
    }

    private func advancePage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            showNotificationPrompt = true
        }
    }

    private func complete() {
        AnalyticsService.shared.track(.onboardingCompleted)
        hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let badge: String?
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(page.iconColor)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            if let badge = page.badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(PremiumManager())
}
