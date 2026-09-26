# Passporte

A SwiftUI iPhone app scaffold set up for iPhone Duo with the iOS 27.1 SDK.

The starter workspace uses `NavigationSplitView` so its navigation adapts as the app moves between the compact outer display and the larger inner display. The Passports and Travel Documents sections are empty starting points for future features.

## Project layout

- `Project.json` defines the iOS app target and deployment settings.
- `App/PassporteApp.swift` is the app entry point.
- `App/ContentView.swift` contains the adaptive navigation shell.
- `App/OverviewView.swift` contains the starter overview screen.
- `App/Assets.xcassets` contains the app icon and accent color.

Open this repository in Bitrig to build and run the app with the iPhone Duo simulator.

## Subscriptions with RevenueCat

The project includes the RevenueCat and RevenueCatUI Swift packages. Tap **Pro** in the app to open the subscription sheet. It uses RevenueCat's current offering and hosted paywall, with purchase and restore callbacks, an active-subscription screen, and subscription management through Apple.

`App/PurchaseStore.swift` owns configuration, offering loading, customer-info updates, and the `hasProAccess` entitlement flag. No existing workspace features are gated yet. Access is derived from RevenueCat customer information rather than a locally stored unlock flag.

Before testing purchases:

1. Connect the intended RevenueCat project and app through the Bitrig RevenueCat plugin.
2. Set `PurchaseConfiguration.publicAPIKey` to that app's **public SDK key**, never a secret API key. The empty default leaves purchases disabled safely.
3. Set `PurchaseConfiguration.entitlementID` to the entitlement used by your products (the scaffold defaults to `pro`).
4. Attach products to that entitlement, add packages to a current offering, and publish its paywall. Configure accurate benefits, pricing, terms of use, privacy policy, and a restore action in the paywall before release.
5. Use a RevenueCat Test Store key and products for simulator purchase testing. Release builds reject Test Store keys. For App Store purchases, connect the real App Store Connect app and matching bundle identifier, configure its products, and test on a device through **Run on…** or TestFlight with a Sandbox Apple Account.

Check purchase success, cancellation, restore with and without an active entitlement, network failures, app relaunch, and entitlement expiry before shipping. The SDK handles purchase presentation and transaction processing; the app updates access from purchase/restore callbacks and the customer-info stream, and refreshes when active.

See [RevenueCat installation](https://www.revenuecat.com/docs/getting-started/installation/ios) and [displaying paywalls](https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls).

## Contributing

Create a branch for your changes, keep commits focused, and include a description of the change and any validation performed when opening a pull request.
