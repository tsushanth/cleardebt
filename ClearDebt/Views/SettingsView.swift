//
//  SettingsView.swift
//  ClearDebt
//
//  App settings and preferences
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Query private var debts: [Debt]

    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var exportContent = ""
    @State private var notificationsEnabled = false
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            List {
                // Premium
                if !premiumManager.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Premium")
                                        .fontWeight(.semibold)
                                    Text("Unlimited debts, custom strategy & more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Premium Active")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Payment Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationManager.shared.requestAuthorization()
                                    notificationsEnabled = granted
                                    if granted {
                                        await NotificationManager.shared.scheduleAllReminders(for: debts)
                                        AnalyticsService.shared.track(.notificationPermissionGranted)
                                    }
                                }
                            } else {
                                NotificationManager.shared.cancelAllReminders()
                            }
                        }
                    if notificationsEnabled {
                        Stepper("Remind \(reminderDaysBefore) days before due", value: $reminderDaysBefore, in: 1...7)
                    }
                }

                // Data
                Section("Data") {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.accentColor)
                            Text("Export Debts as CSV")
                            if !premiumManager.isPremium {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://cleardebt.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://cleardebt.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Rate the App") {
                        // TODO: Request review
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: [exportContent])
            }
            .onAppear {
                Task {
                    await NotificationManager.shared.checkAuthorizationStatus()
                    notificationsEnabled = NotificationManager.shared.isAuthorized
                }
            }
        }
    }

    private func exportData() {
        if !premiumManager.isPremium {
            showPaywall = true
            return
        }
        let vm = DebtListViewModel()
        vm.loadDebts(modelContext: modelContext)
        exportContent = vm.exportCSV()
        showExportSheet = true
        AnalyticsService.shared.track(.exportTriggered)
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: Debt.self, inMemory: true)
        .environment(PremiumManager())
}
