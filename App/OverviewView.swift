import SwiftUI

struct OverviewView: View {
  var openPassports: () -> Void
  var openDocuments: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        VStack(alignment: .leading, spacing: 12) {
          Label("PASSPORTE", systemImage: "airplane.departure")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tint)

          Text("Travel, thoughtfully prepared.")
            .font(.largeTitle.weight(.bold))
            .fixedSize(horizontal: false, vertical: true)

          Text("A home for your passport and essential travel documents.")
            .font(.title3)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: 14) {
          Text("Your library")
            .font(.title2.weight(.semibold))

          LibraryDestinationButton(
            title: "Passports",
            detail: "Keep passport details close at hand.",
            symbol: "person.text.rectangle.fill",
            action: openPassports
          )

          LibraryDestinationButton(
            title: "Travel documents",
            detail: "A place for the documents you need on the go.",
            symbol: "text.document.fill",
            action: openDocuments
          )
        }
      }
      .frame(maxWidth: 680, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .padding(24)
    }
    .navigationTitle("Overview")
  }
}

private struct LibraryDestinationButton: View {
  var title: String
  var detail: String
  var symbol: String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: symbol)
          .font(.title3)
          .foregroundStyle(.tint)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)

          Text(detail)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
