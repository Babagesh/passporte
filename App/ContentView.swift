import SwiftUI

struct ContentView: View {
  var purchases: PurchaseStore
  @State private var showsSubscription = false
  @State private var selection: WorkspaceDestination? = .overview

  var body: some View {
    NavigationSplitView {
      List(WorkspaceDestination.allCases, selection: $selection) { destination in
        Label(destination.title, systemImage: destination.symbol)
          .tag(destination)
      }
      .listStyle(.sidebar)
      .navigationTitle("Passporte")
    } detail: {
      detailView
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Pro") { showsSubscription = true }
              .accessibilityLabel("Pro: Travel Trail")
          }
        }
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showsSubscription) {
      TravelTrailIntroductionView()
    }
  }

  @ViewBuilder
  private var detailView: some View {
    switch selection ?? .overview {
    case .overview:
      OverviewView(
        openPassports: { selection = .passports },
        openDocuments: { selection = .documents }
      )
    case .passports:
      PassportsView(purchases: purchases)
    case .documents:
      let destination = WorkspaceDestination.documents
      ContentUnavailableView(
        destination.emptyTitle,
        systemImage: destination.symbol,
        description: Text(destination.emptyMessage)
      )
      .navigationTitle(destination.title)
    }
  }
}
