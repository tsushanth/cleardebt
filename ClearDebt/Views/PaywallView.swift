//
//  PaywallView.swift
//  ClearDebt
//
//  Premium subscription paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Binding var isPresented: Bool
    @Environment(PremiumManager.self) private var premiumManager

    @State private var storeKitManager = StoreKitManager()
    @State private var selectedProductID: String = StoreKitProductID.yearly.rawValue
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero
                    heroSection

                    // Features
                    featuresSection

                    // Products
                    productsSection

                    // CTA
                    ctaSection

                    // Legal
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.08), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.paywallViewed)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .padding(.top, 20)
            Text("ClearDebt Premium")
                .font(.title)
                .fontWeight(.bold)
            Text("The fastest path to debt freedom")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(premiumFeatures, id: \.title) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 10) {
            if storeKitManager.isLoading {
                ProgressView()
                    .frame(height: 120)
            } else if storeKitManager.allProducts.isEmpty {
                // Fallback static pricing
                ForEach(staticProducts, id: \.id) { product in
                    productRow(id: product.id, title: product.title, price: product.price, period: product.period, badge: product.badge)
                }
            } else {
                ForEach(storeKitManager.subscriptions) { product in
                    Button {
                        selectedProductID = product.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(product.periodLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .font(.headline)
                                .fontWeight(.bold)
                            if selectedProductID == product.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedProductID == product.id ? Color.accentColor : Color(.systemGray4), lineWidth: selectedProductID == product.id ? 2 : 1)
                        )
                        .overlay(
                            Group {
                                if let badge = product.savingsLabel {
                                    Text(badge)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.accentColor)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .offset(y: -12)
                                }
                            },
                            alignment: .topTrailing
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - CTA
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchase() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Premium")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isPurchasing)

            Button("Restore Purchases") {
                Task { await storeKitManager.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        Text("Subscriptions auto-renew unless canceled. Cancel anytime in your App Store settings. See our Terms of Service and Privacy Policy.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Purchase
    private func purchase() async {
        let productID = selectedProductID
        guard let product = storeKitManager.allProducts.first(where: { $0.id == productID }) ??
                            storeKitManager.subscriptions.first else {
            // Fallback: just mark premium for static products
            await premiumManager.refreshPremiumStatus()
            isPresented = false
            return
        }

        isPurchasing = true
        AnalyticsService.shared.track(.purchaseStarted(productID: productID))
        do {
            _ = try await storeKitManager.purchase(product)
            await premiumManager.refreshPremiumStatus()
            AnalyticsService.shared.track(.purchaseCompleted(productID: productID))
            isPresented = false
        } catch StoreKitError.userCancelled {
            // do nothing
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            AnalyticsService.shared.track(.purchaseFailed(reason: error.localizedDescription))
        }
        isPurchasing = false
    }

    // MARK: - Static Data

    struct PremiumFeature {
        let icon: String
        let title: String
        let description: String
    }

    let premiumFeatures: [PremiumFeature] = [
        PremiumFeature(icon: "infinity", title: "Unlimited Debts", description: "Track as many debts as you need"),
        PremiumFeature(icon: "slider.horizontal.3", title: "Custom Strategy", description: "Set your own debt payoff order"),
        PremiumFeature(icon: "square.and.arrow.up", title: "Export Reports", description: "Export your plan as CSV or PDF"),
        PremiumFeature(icon: "bell.badge.fill", title: "Smart Reminders", description: "Never miss a payment again"),
        PremiumFeature(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Deep insights into your progress"),
    ]

    struct StaticProduct: Identifiable {
        let id: String
        let title: String
        let price: String
        let period: String
        let badge: String?
    }

    let staticProducts: [StaticProduct] = [
        StaticProduct(id: StoreKitProductID.monthly.rawValue, title: "Monthly", price: "$4.99", period: "per month", badge: nil),
        StaticProduct(id: StoreKitProductID.yearly.rawValue, title: "Yearly", price: "$29.99", period: "per year", badge: "Best Value"),
        StaticProduct(id: StoreKitProductID.lifetime.rawValue, title: "Lifetime", price: "$79.99", period: "one-time", badge: nil),
    ]

    private func productRow(id: String, title: String, price: String, period: String, badge: String?) -> some View {
        Button {
            selectedProductID = id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Text(period).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price).font(.headline).fontWeight(.bold)
                if selectedProductID == id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedProductID == id ? Color.accentColor : Color(.systemGray4), lineWidth: selectedProductID == id ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
        .environment(PremiumManager())
}
