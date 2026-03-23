// Copyright © 2021 Al Jawziyya. All rights reserved.

import Foundation
import RevenueCat
import RevenueCatUI
import Combine
import UIKit
import StoreKit

enum AzkarEntitlement: String {
    case pro = "azkar_pro"
    case proPlus = "azkar_pro_plus"
    case ultra = "azkar_ultra"
    case ultraUniversal = "azkar_ultra_universal"
}

final class SubscriptionManager: SubscriptionManagerType {

    private enum PaywallDismissReason {
        case purchased
        case restored
    }

    @Preference(Keys.enableProFeatures, defaultValue: false)
    var enableProFeatures: Bool

    @Preference("kLastPaywallDeclineDate", defaultValue: nil)
    var lastPaywallDeclineDate: Date?

    static let shared = SubscriptionManager()

    private var paywallSourceScreenName: String?
    private var paywallCompletion: (() -> Void)?
    private var paywallDismissReason: PaywallDismissReason?

    private init() {}

    func getUserRegion() -> UserRegion {
        if let storeFront = SKPaymentQueue.default().storefront {
            let code = storeFront.countryCode
            return UserRegion(rawValue: code) ?? .other
        } else {
            return .other
        }
    }

    // MARK: - Subscription Status

    func observeSubscriptionStatus() {
        assert(Purchases.isConfigured, "You must configure RevenueCat before calling this method.")
        Task {
            if let customerInfo = try? await Purchases.shared.customerInfo() {
                await updateProStatus(from: customerInfo)
            }
            for await customerInfo in Purchases.shared.customerInfoStream {
                await updateProStatus(from: customerInfo)
            }
        }
    }

    @MainActor
    private func updateProStatus(from customerInfo: CustomerInfo) {
        let hasActiveEntitlement = customerInfo.entitlements.activeInCurrentEnvironment.isEmpty == false
        setProFeaturesActivated(hasActiveEntitlement)
    }

    // MARK: - Paywall Presentation

    func presentPaywall(presentationType: PaywallPresentationType, completion: (() -> Void)?) {
        let sourceScreenName: String
        switch presentationType {
        case .appLaunch:
            sourceScreenName = "app_launch"
            if let lastPaywallDeclineDate {
                let days = Calendar.current.dateComponents([.day], from: lastPaywallDeclineDate, to: Date()).day ?? 0
                guard days > 2 else {
                    completion?()
                    return
                }
            }
        case .screen(let screenName):
            sourceScreenName = screenName
        }

        self.paywallSourceScreenName = sourceScreenName
        self.paywallCompletion = completion
        self.paywallDismissReason = nil

        let controller = PaywallViewController(
            offeringIdentifier: "monthly_azkar_pro",
            displayCloseButton: true
        )
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController?.topmostPresentedViewController else {
            resetPaywallState()
            completion?()
            return
        }

        AnalyticsReporter.reportEvent("paywall_presentation", metadata: [
            "source": sourceScreenName,
            "entitlement": AzkarEntitlement.ultraUniversal.rawValue,
        ])

        rootVC.present(controller, animated: true)
    }

    func isProUser() -> Bool {
        if UIDevice.current.isMac {
            return true
        } else {
            #if DEBUG
            return CommandLine.arguments.contains("ENABLE_PRO") || enableProFeatures
            #else
            return enableProFeatures
            #endif
        }
    }

    func setProFeaturesActivated(_ flag: Bool) {
        enableProFeatures = flag
    }

    private func resetPaywallState() {
        paywallSourceScreenName = nil
        paywallCompletion = nil
    }

}

// MARK: - PaywallViewControllerDelegate

extension SubscriptionManager: PaywallViewControllerDelegate {

    func paywallViewController(_ controller: PaywallViewController, didFinishPurchasingWith customerInfo: CustomerInfo) {
        paywallDismissReason = .purchased
        setProFeaturesActivated(true)
        Task { @MainActor [weak self] in
            self?.updateProStatus(from: customerInfo)
        }
        AnalyticsReporter.reportEvent("paywall_dismiss", metadata: [
            "reason": "purchased",
            "source": paywallSourceScreenName ?? "unknown",
            "entitlement": AzkarEntitlement.ultraUniversal.rawValue,
        ])
        controller.dismiss(animated: true) { [weak self] in
            self?.paywallCompletion?()
            self?.resetPaywallState()
        }
    }

    func paywallViewController(_ controller: PaywallViewController, didFinishRestoringWith customerInfo: CustomerInfo) {
        paywallDismissReason = .restored
        setProFeaturesActivated(true)
        Task { @MainActor [weak self] in
            self?.updateProStatus(from: customerInfo)
        }
        AnalyticsReporter.reportEvent("paywall_dismiss", metadata: [
            "reason": "restored",
            "source": paywallSourceScreenName ?? "unknown",
            "entitlement": AzkarEntitlement.ultraUniversal.rawValue,
        ])
        controller.dismiss(animated: true) { [weak self] in
            self?.paywallCompletion?()
            self?.resetPaywallState()
        }
    }

    func paywallViewController(_ controller: PaywallViewController, didFailPurchasingWith error: NSError) {
        AnalyticsReporter.reportEvent("purchase_attempt_error", metadata: [
            "error": error.localizedDescription,
            "source": paywallSourceScreenName ?? "unknown",
        ])
    }

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {
        guard paywallDismissReason == nil else {
            return
        }

        lastPaywallDeclineDate = Date()
        AnalyticsReporter.reportEvent("paywall_dismiss", metadata: [
            "reason": "declined",
            "source": paywallSourceScreenName ?? "unknown",
            "entitlement": AzkarEntitlement.ultraUniversal.rawValue,
        ])
        paywallCompletion?()
        resetPaywallState()
    }

}
