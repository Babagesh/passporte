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

The project includes the RevenueCat and RevenueCatUI Swift packages. **Pro** now opens the Travel Trail demo; it never presents a paywall or starts a purchase. The earlier subscription framework remains in `SubscriptionView.swift` for future use but is not linked from the demo.

## Travel Trail demo

Travel Trail presents a mock active trip to Japan: Tokyo → Kamakura → Tokyo → Kyoto → Osaka. The journal shows four distinct cities, approximately 620 km traveled, day 5 of 9, and Osaka as the latest stop. Select a timeline entry to highlight it on the map, or use Replay to trace the journey. Distances are mock totals; map segments are illustrative, not navigation directions.

On the Duo inner display, the two pages share the available space. Active division regions place the map on the left and the timeline on the right in book posture, or the map above the controls in tabletop posture. iOS 27.1 `onHingeChange` drives the fold angle indicator and page shading. On the outer display, the same pages stack and scroll. Selection is retained through layout changes. Map tiles require a network connection; no location permission is needed.

The **Demo** toolbar action opens a persisted **Pass unlocked** toggle, enabled by default. This local override deliberately controls both locked and unlocked demo states, independently of real purchases. The SDK separately observes the `travel_trail_pass` entitlement in `customerInfo.entitlements.active` and displays its state in the demo settings. This mock identifier must be configured in RevenueCat before enabling live gating; no dashboard products or entitlements are created by this demo. Core US passport and visa information remains free, and the United States remains the only passport type.

To test folding, use Bitrig's Fold controls and rotate the simulator into tabletop orientation. Simulator automation cannot change the fold state. Verify that the map stays above the timeline controls and that the angle readout and page shading react as you fold.

### Future live purchase setup

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
