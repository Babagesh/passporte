import SwiftUI

struct ContentView: View {
  @State private var selection: WorkspaceDestination? = .overview
  @State private var stampStore = StampBookStore()

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
    }
    .navigationSplitViewStyle(.balanced)
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
      PassportsView(store: stampStore)
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
