import Foundation

enum PurchaseConfiguration {
  // Public SDK key only. Never put a RevenueCat secret API key in the app.
  static let publicAPIKey = ""
  // Must match the entitlement attached to products in RevenueCat.
  static let entitlementID = "pro"
}
