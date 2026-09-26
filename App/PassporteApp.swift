import SwiftUI

@main
struct PassporteApp: App {
  @State private var purchases = PurchaseStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      ContentView(purchases: purchases)
        .task {
          purchases.configure()
          await purchases.refreshAccess()
          await purchases.observeCustomerInfo()
        }
        .onChange(of: scenePhase) { _, phase in
          if phase == .active {
            Task { await purchases.refreshAccess() }
          }
        }
    }
  }
}
