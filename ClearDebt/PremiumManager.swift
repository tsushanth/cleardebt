//
//  PremiumManager.swift
//  ClearDebt
//
//  Manages premium subscription status across the app
//

import Foundation
import StoreKit

@MainActor
@Observable
final class PremiumManager {

    private(set) var isPremium: Bool = false
    private let storeKitManager = StoreKitManager()
    private let premiumKey = "com.appfactory.cleardebt.isPremium"

    init() {
        // Check cached premium status first
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }

    func refreshPremiumStatus() async {
        await storeKitManager.updatePurchasedProducts()
        let newStatus = storeKitManager.isPremium
        isPremium = newStatus
        UserDefaults.standard.set(newStatus, forKey: premiumKey)
    }

    // For previews / testing
    func setDebugPremium(_ value: Bool) {
        #if DEBUG
        isPremium = value
        UserDefaults.standard.set(value, forKey: premiumKey)
        #endif
    }
}
