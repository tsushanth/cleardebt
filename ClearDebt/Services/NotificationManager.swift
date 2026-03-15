//
//  NotificationManager.swift
//  ClearDebt
//
//  Manages local notifications for payment reminders
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let categoryID = "PAYMENT_REMINDER"
    private let reminderPrefix = "debt_reminder_"

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("[NotificationManager] Authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Reminders

    func schedulePaymentReminder(for debt: Debt, daysBefore: Int = 3) async {
        guard isAuthorized else { return }

        let identifier = "\(reminderPrefix)\(debt.id.uuidString)"
        let dueDay = debt.dueDate

        // Create a monthly trigger for the due date minus daysBefore
        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let reminderDay = max(1, dueDay - daysBefore)
        components.day = reminderDay

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let amountString = formatter.string(from: NSNumber(value: debt.minimumPayment)) ?? "$\(debt.minimumPayment)"

        let content = UNMutableNotificationContent()
        content.title = "Payment Due Soon: \(debt.name)"
        content.body = "Your \(debt.name) payment of \(amountString) is due on the \(dueDay)th. Tap to log payment."
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.userInfo = ["debtID": debt.id.uuidString, "debtName": debt.name]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            print("[NotificationManager] Scheduled reminder for \(debt.name)")
        } catch {
            print("[NotificationManager] Failed to schedule: \(error)")
        }
    }

    func scheduleAllReminders(for debts: [Debt]) async {
        for debt in debts where !debt.isPaidOff {
            await schedulePaymentReminder(for: debt)
        }
    }

    // MARK: - Cancel Reminders

    func cancelReminder(for debt: Debt) {
        let identifier = "\(reminderPrefix)\(debt.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Motivational Notifications

    func sendMilestoneNotification(title: String, body: String) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("[NotificationManager] Failed to send milestone notification: \(error)")
        }
    }

    // MARK: - Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
}
