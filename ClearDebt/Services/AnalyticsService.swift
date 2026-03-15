//
//  AnalyticsService.swift
//  ClearDebt
//
//  Lightweight analytics event tracking (Firebase-ready stub)
//

import Foundation

// MARK: - Analytics Events
enum AnalyticsEvent {
    case appOpen
    case onboardingCompleted
    case debtAdded(type: String)
    case debtPaidOff(name: String)
    case strategyChanged(strategy: String)
    case budgetUpdated
    case paymentLogged(amount: Double)
    case milestoneReached(title: String)
    case paywallViewed
    case purchaseStarted(productID: String)
    case purchaseCompleted(productID: String)
    case purchaseFailed(reason: String)
    case exportTriggered
    case notificationPermissionGranted
    case reminderScheduled

    var name: String {
        switch self {
        case .appOpen:                    return "app_open"
        case .onboardingCompleted:        return "onboarding_completed"
        case .debtAdded:                  return "debt_added"
        case .debtPaidOff:               return "debt_paid_off"
        case .strategyChanged:           return "strategy_changed"
        case .budgetUpdated:             return "budget_updated"
        case .paymentLogged:             return "payment_logged"
        case .milestoneReached:          return "milestone_reached"
        case .paywallViewed:             return "paywall_viewed"
        case .purchaseStarted:           return "purchase_started"
        case .purchaseCompleted:         return "purchase_completed"
        case .purchaseFailed:            return "purchase_failed"
        case .exportTriggered:           return "export_triggered"
        case .notificationPermissionGranted: return "notification_permission_granted"
        case .reminderScheduled:         return "reminder_scheduled"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .debtAdded(let type):            return ["debt_type": type]
        case .debtPaidOff(let name):          return ["debt_name": name]
        case .strategyChanged(let strategy):  return ["strategy": strategy]
        case .paymentLogged(let amount):      return ["amount": amount]
        case .milestoneReached(let title):    return ["title": title]
        case .purchaseStarted(let id):        return ["product_id": id]
        case .purchaseCompleted(let id):      return ["product_id": id]
        case .purchaseFailed(let reason):     return ["reason": reason]
        default:                              return [:]
        }
    }
}

// MARK: - Analytics Service
@MainActor
final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    private var isInitialized = false

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        #if DEBUG
        print("[Analytics] Initialized")
        #endif
    }

    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif
        // TODO: Wire up Firebase Analytics or Mixpanel
        // Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] setUserProperty \(name) = \(value ?? "nil")")
        #endif
    }
}
