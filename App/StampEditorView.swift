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
    Form {
      Section("Destination") {
        Picker("Country", selection: $country) {
          ForEach(TravelCountry.allCases) { country in
            Text(country.displayName).tag(country)
          }
        }
        .pickerStyle(.menu)
      }

      Section("Travel dates") {
        DatePicker("Arrival", selection: $entryDate, displayedComponents: .date)
        DatePicker(
          "Departure",
          selection: $exitDate,
          in: entryDate...Date.distantFuture,
          displayedComponents: .date
        )
      }

      Section {
        ForEach($diaryEntries) { $entry in
          HStack(alignment: .top, spacing: 12) {
            Circle()
              .fill(.secondary)
              .frame(width: 5, height: 5)
              .padding(.top, 9)
              .accessibilityHidden(true)

            TextField("Write a moment from this trip", text: $entry.text, axis: .vertical)
              .lineLimit(1...4)

            Button(role: .destructive) {
              diaryEntries.removeAll { $0.id == entry.id }
            } label: {
              Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove diary entry")
          }
        }

        Button("Add a note", systemImage: "plus") {
          diaryEntries.append(DiaryEntryDraft())
        }
      } header: {
        Text("Diary")
      } footer: {
        Text("Add a short note for each moment you want to remember.")
      }

      Section {
        if photoAssets.isEmpty {
          ContentUnavailableView(
            "No photos yet",
            systemImage: "photo",
            description: Text("Add a few photos to keep with this stamp.")
          )
          .frame(maxWidth: .infinity)
          .listRowBackground(Color.clear)
        } else {
          ScrollView(.horizontal) {
            HStack(spacing: 12) {
              ForEach(photoAssets) { photo in
                StampPhotoThumbnail(photo: photo) {
                  photoAssets.removeAll { $0.id == photo.id }
                }
              }
            }
            .padding(.vertical, 4)
          }
          .scrollIndicators(.hidden)
          .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }

        HStack {
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

        if !cameraAvailable {
          Text("Camera capture is unavailable on this device.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } header: {
        Text("Photos")
      } footer: {
        Text("Add up to 12 photos. You can choose existing pictures or take a new one.")
      }
    }
    .navigationTitle(store.stamps.contains(where: { $0.id == stamp.id })
      ? "Edit Stamp"
      : "New Stamp")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }

      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveStamp()
        }
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

private struct StampPhotoThumbnail: View {
  var photo: StampPhotoAsset
  var onRemove: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      if let image = photo.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 104, height: 88)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }

      Button(role: .destructive, action: onRemove) {
        Image(systemName: "xmark")
          .font(.caption.weight(.bold))
          .foregroundStyle(.white)
          .padding(6)
          .background(.black.opacity(0.65), in: Circle())
      }
      .buttonStyle(.plain)
      .padding(5)
      .accessibilityLabel("Remove photo")
    }
  }
}
