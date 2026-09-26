import Observation
import RevenueCat
import Foundation

@MainActor
@Observable
final class PurchaseStore {
  // Demo override is intentionally independent of paid access, so both states
  // can be demonstrated without changing a real customer's entitlement.
  var demoTrailPassUnlocked = UserDefaults.standard.object(forKey: "demoTrailPassUnlocked") as? Bool ?? true {
    didSet { UserDefaults.standard.set(demoTrailPassUnlocked, forKey: "demoTrailPassUnlocked") }
  }
  private(set) var hasRevenueCatTravelTrailPass = false
  var hasTravelTrailAccess: Bool { demoTrailPassUnlocked }
  private(set) var isConfigured = false
  private(set) var hasProAccess = false
  private(set) var offering: Offering?
  private(set) var isLoading = false
  private(set) var isRestoring = false
  var message: String?

  var showsMessage: Bool {
    get { message != nil && offering != nil }
    set { if !newValue { message = nil } }
  }

  func configure() {
    guard !isConfigured else { return }
    let key = PurchaseConfiguration.publicAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !key.isEmpty else { return }
    #if DEBUG
    Purchases.logLevel = .debug
    #else
    guard !key.hasPrefix("test_") else { return }
    #endif
    Purchases.configure(withAPIKey: key)
    isConfigured = true
  }

  func observeCustomerInfo() async {
    guard isConfigured else { return }
    for await info in Purchases.shared.customerInfoStream {
      guard !Task.isCancelled else { return }
      update(info)
    }
  }

  func refreshAccess() async {
    guard isConfigured else { return }
    do {
      update(try await Purchases.shared.customerInfo())
    } catch {
      message = "Couldn’t check your subscription. Please try again."
    }
  }

  func loadOffering() async {
    guard isConfigured, !isLoading else { return }
    isLoading = true
    message = nil
    defer { isLoading = false }
    do {
      offering = try await Purchases.shared.offerings().current
      if offering?.availablePackages.isEmpty != false {
        offering = nil
        message = "No plans are available right now. Please try again later."
      }
    } catch {
      offering = nil
      message = "Couldn’t load plans. Check your connection and try again."
    }
  }

  func restore() async {
    guard isConfigured, !isRestoring else { return }
    isRestoring = true
    defer { isRestoring = false }
    do {
      restored(try await Purchases.shared.restorePurchases())
    } catch {
      message = "Couldn’t restore purchases. Please try again."
    }
  }

  func restored(_ info: CustomerInfo) {
    update(info)
    message = hasProAccess ? "Your purchases have been restored." : "No active Pro subscription was found."
  }

  func update(_ info: CustomerInfo) {
    hasRevenueCatTravelTrailPass = info.entitlements.active["travel_trail_pass"] != nil
    hasProAccess = info.entitlements[PurchaseConfiguration.entitlementID]?.isActive == true
  }
}
