import SwiftUI

struct TravelTrailIntroductionView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Image(systemName: "map")
            .font(.largeTitle)
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
          Text("Meet Travel Trail")
            .font(.largeTitle.bold())
          Text("Your trip, one memorable stop at a time.")
            .font(.title3)
          Text("Follow the trips you've stamped into your passport on an animated map, see your travel stats, and revisit each stop in a chronological timeline. On iPhone Duo, the pages adapt as you fold.")
          VStack(alignment: .leading, spacing: 8) {
            Text("Open it from your passport").font(.headline)
            Text("Open a passport to its inside pages, then tap the map button in the toolbar.")
          }
          Text("Travel Trail Pass is unlocked for this demo. No payment is required, and your core passport and visa information stays free.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .navigationTitle("Passporte Pro")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }
}
