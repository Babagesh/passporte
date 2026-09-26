import SwiftUI
import RevenueCatUI
import StoreKit

struct SubscriptionView: View {
  @Bindable var purchases: PurchaseStore
  @Environment(\.dismiss) private var dismiss
  @State private var showsManagement = false

  var body: some View {
    NavigationStack {
      Group {
        if purchases.hasProAccess {
          Form {
            Section {
              Text("Your Pro subscription is active.")
              Button("Manage Subscription") { showsManagement = true }
            }
          }
        } else if !purchases.isConfigured {
          VStack(spacing: 16) {
            Text("Subscriptions coming soon").font(.title2.bold())
            Text("Plans aren’t available yet. You can continue using Passporte.")
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if purchases.isLoading {
          ProgressView("Loading plans…")
        } else if let offering = purchases.offering {
          PaywallView(offering: offering)
            .onPurchaseCompleted { info in purchases.update(info) }
            .onRestoreCompleted { info in purchases.restored(info) }
            .onPurchaseFailure { _ in
              purchases.message = "Your purchase couldn’t be completed. Please try again."
            }
            .onRestoreFailure { _ in
              purchases.message = "Couldn’t restore purchases. Please try again."
            }
        } else {
          VStack(spacing: 16) {
            Text("Plans unavailable").font(.title2.bold())
            Text(purchases.message ?? "Please try again later.")
              .multilineTextAlignment(.center)
            Button("Try Again") { Task { await purchases.loadOffering() } }
              .buttonStyle(.borderedProminent)
            Button(purchases.isRestoring ? "Restoring…" : "Restore Purchases") {
              Task { await purchases.restore() }
            }
            .disabled(purchases.isRestoring)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .navigationTitle("Passporte Pro")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .manageSubscriptionsSheet(isPresented: $showsManagement)
      .task { await purchases.loadOffering() }
      .alert("Subscription", isPresented: $purchases.showsMessage) {
        Button("OK", role: .cancel) { purchases.message = nil }
      } message: {
        Text(purchases.message ?? "")
      }
    }
  }
}
