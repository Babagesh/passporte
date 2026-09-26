import SwiftUI

struct StampDetailsPanel: View {
  @State private var photos: [StampPhotoAsset] = []

  var stamp: TravelStamp
  var store: StampBookStore
  var onClose: () -> Void
  var onExpand: () -> Void
  var onEdit: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        StampDetailsHeader(
          country: stamp.country,
          onEdit: onEdit,
          onExpand: onExpand,
          onClose: onClose
        )

        StampTravelDates(entryDate: stamp.entryDate, exitDate: stamp.exitDate)

        StampDetailsPhotos(photos: photos)

        StampDiaryNotes(entries: stamp.diaryEntries)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
    }
    .background(.background)
    .task(id: stamp.photoIDs) {
      photos = store.photoAssets(for: stamp)
    }
  }
}

private struct StampDetailsHeader: View {
  var country: TravelCountry
  var onEdit: () -> Void
  var onExpand: () -> Void
  var onClose: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("VISA STAMP")
          .font(.caption.weight(.semibold))
          .tracking(1.2)
          .foregroundStyle(.secondary)

        Text(country.displayName)
          .font(.title2.weight(.bold))
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 4)

      HStack(spacing: 8) {
        Button("Edit stamp", systemImage: "pencil", action: onEdit)
          .labelStyle(.iconOnly)
          .buttonStyle(.bordered)
        Button("Expand details", systemImage: "arrow.up.left.and.arrow.down.right", action: onExpand)
          .labelStyle(.iconOnly)
          .buttonStyle(.bordered)
        Button("Close details", systemImage: "xmark", action: onClose)
          .labelStyle(.iconOnly)
          .buttonStyle(.bordered)
      }
      .controlSize(.small)
    }
  }
}

private struct StampTravelDates: View {
  var entryDate: Date
  var exitDate: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("TRAVEL DATES")
        .font(.caption.weight(.semibold))
        .tracking(1)
        .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        dateCard(title: "Arrival", date: entryDate)
        dateCard(title: "Departure", date: exitDate)
      }
    }
  }

  private func dateCard(title: String, date: Date) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: "calendar")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(date, format: .dateTime.day().month(.abbreviated).year())
        .font(.subheadline.weight(.semibold))
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}

private struct StampDetailsPhotos: View {
  var photos: [StampPhotoAsset]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("PHOTOS")
          .font(.caption.weight(.semibold))
          .tracking(1)
          .foregroundStyle(.secondary)
        Spacer()
        if !photos.isEmpty {
          Text("\(photos.count)")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
      }

      if photos.isEmpty {
        Label("No photos added", systemImage: "photo")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
      } else {
        ScrollView(.horizontal) {
          HStack(spacing: 12) {
            ForEach(photos) { photo in
              if let image = photo.image {
                Image(uiImage: image)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 190, height: 140)
                  .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                  .accessibilityLabel("Trip photo")
              }
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
  }
}

private struct StampDiaryNotes: View {
  var entries: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("DIARY")
        .font(.caption.weight(.semibold))
        .tracking(1)
        .foregroundStyle(.secondary)

      if entries.isEmpty {
        Text("No diary notes added yet.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
            HStack(alignment: .top, spacing: 12) {
              Circle()
                .fill(.tint)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
                .accessibilityHidden(true)

              Text(entry)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      }
    }
  }
}
