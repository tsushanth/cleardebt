//
//  ContentView.swift
//  ClearDebt
//
//  Root view with tab navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            mainTabView
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            DebtListView()
                .tabItem {
                    Label("Debts", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            PayoffPlanView()
                .tabItem {
                    Label("Plan", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            MilestonesView()
                .tabItem {
                    Label("Milestones", systemImage: "star.fill")
                }
                .tag(3)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign.circle.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Debt.self, PayoffPlan.self, PaymentRecord.self, Milestone.self, Budget.self], inMemory: true)
        .environment(PremiumManager())
}
