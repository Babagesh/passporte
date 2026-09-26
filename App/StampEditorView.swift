import PhotosUI
import SwiftUI
import UIKit

struct StampEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var country: TravelCountry
  @State private var entryDate: Date
  @State private var exitDate: Date
  @State private var diaryEntries: [DiaryEntryDraft]
  @State private var photoAssets: [StampPhotoAsset] = []
  @State private var arePhotosLoaded = false
  @State private var selectedPhotos: [PhotosPickerItem] = []
  @State private var isCameraPresented = false
  @State private var saveErrorMessage = ""
  @State private var isSaveErrorPresented = false

  var stamp: TravelStamp
  var store: StampBookStore

  init(stamp: TravelStamp, store: StampBookStore) {
    self.stamp = stamp
    self.store = store
    _country = State(initialValue: stamp.country)
    _entryDate = State(initialValue: stamp.entryDate)
    _exitDate = State(initialValue: max(stamp.exitDate, stamp.entryDate))
    _diaryEntries = State(
      initialValue: stamp.diaryEntries.isEmpty
        ? [DiaryEntryDraft()]
        : stamp.diaryEntries.map { DiaryEntryDraft(text: $0) }
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 26) {
        stampPreview
        destinationCard
        datesCard
        diaryCard
        photosCard
      }
      .padding(.horizontal, 22)
      .padding(.vertical, 26)
      .frame(maxWidth: 640)
      .frame(maxWidth: .infinity)
    }
    .background { ScrapbookBackground() }
    .tint(ScrapbookPalette.accent)
    .navigationTitle(isExistingStamp ? "Edit Stamp" : "New Stamp")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(ScrapbookPalette.paperEdge, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
        .foregroundStyle(ScrapbookPalette.inkSoft)
      }

      ToolbarItem(placement: .confirmationAction) {
        Button(isExistingStamp ? "Save" : "Paste In") {
          saveStamp()
        }
        .fontWeight(.bold)
        .disabled(!arePhotosLoaded)
      }
    }
    .task(id: stamp.id) {
      photoAssets = store.photoAssets(for: stamp)
      arePhotosLoaded = true
    }
    .onChange(of: entryDate) { _, newDate in
      if exitDate < newDate {
        exitDate = newDate
      }
    }
    .onChange(of: selectedPhotos) { _, items in
      guard !items.isEmpty else {
        return
      }

      Task {
        await importPhotos(items)
      }
    }
    .fullScreenCover(isPresented: $isCameraPresented) {
      CameraCaptureView { image in
        if let photo = StampPhotoAsset.compressed(from: image) {
          photoAssets.append(photo)
        }
        isCameraPresented = false
      } onCancel: {
        isCameraPresented = false
      }
      .ignoresSafeArea()
    }
    .alert("Couldn't save stamp", isPresented: $isSaveErrorPresented) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(saveErrorMessage)
    }
  }

  private var isExistingStamp: Bool {
    store.stamps.contains { $0.id == stamp.id }
  }

  /// The stamp as it will land on the page, so the edits read like a rubber stamp proof.
  private var previewStamp: TravelStamp {
    TravelStamp(
      id: stamp.id,
      country: country,
      entryDate: entryDate,
      exitDate: exitDate,
      diaryEntries: diaryEntries.map(\.text),
      photoIDs: photoAssets.map(\.id)
    )
  }

  private var stampPreview: some View {
    VStack(spacing: 10) {
      Text("Passporte · Travel Log")
        .font(.system(size: 12, weight: .semibold, design: .serif))
        .tracking(3)
        .foregroundStyle(ScrapbookPalette.inkSoft)

      VisaStampArtwork(stamp: previewStamp, tilt: -3, height: 150)
        .padding(18)
        .background(ScrapbookPalette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(ScrapbookPalette.ink.opacity(0.7), lineWidth: 3)
        }
        .shadow(color: ScrapbookPalette.ink.opacity(0.22), radius: 10, x: 2, y: 7)
        .overlay(alignment: .topTrailing) {
          WashiTape(width: 74, tilt: 9)
            .offset(x: -16, y: -10)
        }
        .rotationEffect(.degrees(-1.2))
    }
  }

  private var destinationCard: some View {
    ScrapbookCard(title: "Destination", symbol: "mappin.and.ellipse", tilt: -0.6) {
      VStack(alignment: .leading, spacing: 12) {
        Picker("Country", selection: $country) {
          ForEach(TravelCountry.allCases) { country in
            Text(country.displayName).tag(country)
          }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .font(.system(size: 17, weight: .semibold, design: .serif))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ScrapbookPalette.paperEdge, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(ScrapbookPalette.ink.opacity(0.55), lineWidth: 1.6)
        }

        Text(country.rawValue)
          .font(.system(size: 34, weight: .black, design: .serif))
          .tracking(6)
          .foregroundStyle(ScrapbookPalette.ink.opacity(0.18))
      }
    }
  }

  private var datesCard: some View {
    ScrapbookCard(title: "Travel dates", symbol: "calendar", tilt: 0.7) {
      VStack(spacing: 14) {
        DatePicker("Arrival", selection: $entryDate, displayedComponents: .date)
        ScrapbookCutLine()
        DatePicker(
          "Departure",
          selection: $exitDate,
          in: entryDate...Date.distantFuture,
          displayedComponents: .date
        )
      }
      .font(.system(size: 15, weight: .semibold, design: .serif))
      .foregroundStyle(ScrapbookPalette.ink)
    }
  }

  private var diaryCard: some View {
    ScrapbookCard(title: "Diary", symbol: "text.book.closed.fill", tilt: -0.5) {
      VStack(alignment: .leading, spacing: 14) {
        ForEach($diaryEntries) { $entry in
          HStack(alignment: .top, spacing: 10) {
            Text("✎")
              .font(.system(size: 15))
              .foregroundStyle(ScrapbookPalette.accent)
              .padding(.top, 2)
              .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
              TextField("Write a moment from this trip", text: $entry.text, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(ScrapbookPalette.ink)

              ScrapbookCutLine()
            }

            Button(role: .destructive) {
              diaryEntries.removeAll { $0.id == entry.id }
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove diary entry")
          }
        }

        Button("Add a note", systemImage: "plus") {
          diaryEntries.append(DiaryEntryDraft())
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .buttonStyle(.borderless)
      }
    }
  }

  private var photosCard: some View {
    ScrapbookCard(title: "Photos", symbol: "photo.stack.fill", tilt: 0.6) {
      VStack(alignment: .leading, spacing: 16) {
        if photoAssets.isEmpty {
          VStack(spacing: 6) {
            Image(systemName: "photo.badge.plus")
              .font(.system(size: 22, weight: .semibold))
            Text("Tape in a few photos")
              .font(.system(size: 14, weight: .semibold, design: .serif))
          }
          .foregroundStyle(ScrapbookPalette.inkSoft.opacity(0.75))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 22)
          .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(
                ScrapbookPalette.inkSoft.opacity(0.45),
                style: StrokeStyle(lineWidth: 1.6, dash: [6, 5])
              )
          }
        } else {
          ScrollView(.horizontal) {
            HStack(spacing: 16) {
              ForEach(Array(photoAssets.enumerated()), id: \.element.id) { index, photo in
                StampPhotoThumbnail(photo: photo, tilt: index.isMultiple(of: 2) ? -2.5 : 2.5) {
                  photoAssets.removeAll { $0.id == photo.id }
                }
              }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
          }
          .scrollIndicators(.hidden)
        }

        HStack(spacing: 10) {
          PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: max(1, 12 - photoAssets.count),
            matching: .images
          ) {
            Label("Choose Photos", systemImage: "photo")
          }
          .buttonStyle(.bordered)
          .disabled(photoAssets.count >= 12)

          Button("Take Photo", systemImage: "camera.fill") {
            isCameraPresented = true
          }
          .buttonStyle(.bordered)
          .disabled(!cameraAvailable || photoAssets.count >= 12)
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .controlSize(.regular)

        Text(cameraAvailable
          ? "Up to 12 photos — choose existing pictures or take a new one."
          : "Camera capture is unavailable on this device.")
          .font(.system(size: 12, design: .serif))
          .foregroundStyle(ScrapbookPalette.inkSoft)
      }
    }
  }

  private var cameraAvailable: Bool {
    UIImagePickerController.isSourceTypeAvailable(.camera)
  }

  @MainActor
  private func importPhotos(_ items: [PhotosPickerItem]) async {
    let remainingSlots = max(0, 12 - photoAssets.count)
    for item in items.prefix(remainingSlots) {
      guard
        let data = try? await item.loadTransferable(type: Data.self),
        let photo = StampPhotoAsset.compressed(from: data)
      else {
        continue
      }
      photoAssets.append(photo)
    }
    selectedPhotos = []
  }

  private func saveStamp() {
    let savedStamp = TravelStamp(
      id: stamp.id,
      country: country,
      entryDate: entryDate,
      exitDate: exitDate,
      diaryEntries: diaryEntries.map(\.text),
      photoIDs: stamp.photoIDs
    )

    do {
      try store.save(savedStamp, photos: photoAssets)
      dismiss()
    } catch {
      saveErrorMessage = error.localizedDescription
      isSaveErrorPresented = true
    }
  }
}

private struct DiaryEntryDraft: Identifiable {
  var id = UUID()
  var text = ""

  init(id: UUID = UUID(), text: String = "") {
    self.id = id
    self.text = text
  }
}

/// A photo pasted in like a print, with a white border and a little tilt.
private struct StampPhotoThumbnail: View {
  var photo: StampPhotoAsset
  var tilt: Double
  var onRemove: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      if let image = photo.image {
        VStack(spacing: 0) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 112, height: 88)
            .clipped()

          Rectangle()
            .fill(.white)
            .frame(height: 16)
        }
        .padding(6)
        .background(.white)
        .overlay {
          Rectangle()
            .strokeBorder(ScrapbookPalette.ink.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: ScrapbookPalette.ink.opacity(0.24), radius: 5, x: 2, y: 3)
      }

      Button(role: .destructive, action: onRemove) {
        Image(systemName: "xmark")
          .font(.caption.weight(.bold))
          .foregroundStyle(.white)
          .padding(6)
          .background(ScrapbookPalette.ink.opacity(0.8), in: Circle())
      }
      .buttonStyle(.plain)
      .padding(2)
      .accessibilityLabel("Remove photo")
    }
    .rotationEffect(.degrees(tilt))
  }
}
