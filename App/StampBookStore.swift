import Foundation
import Observation

@MainActor
@Observable
final class StampBookStore {
  private(set) var stamps: [TravelStamp] = []

  @ObservationIgnored private let storageURL: URL

  init() {
    let applicationSupport = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0]
    storageURL = applicationSupport
      .appendingPathComponent("Passporte", isDirectory: true)
      .appendingPathComponent("StampBook", isDirectory: true)
    load()
  }

  var pageCount: Int {
    max(1, (stamps.count + 5) / 6)
  }

  func photoAsset(for id: UUID) -> StampPhotoAsset? {
    guard let data = try? Data(contentsOf: photoURL(for: id)) else {
      return nil
    }

    return StampPhotoAsset(id: id, data: data)
  }

  func photoAssets(for stamp: TravelStamp) -> [StampPhotoAsset] {
    stamp.photoIDs.compactMap(photoAsset(for:))
  }

  func save(_ stamp: TravelStamp, photos: [StampPhotoAsset]) throws {
    try FileManager.default.createDirectory(
      at: storageURL,
      withIntermediateDirectories: true
    )

    let previousPhotoIDs = stamps.first(where: { $0.id == stamp.id })?.photoIDs ?? []
    var savedStamp = stamp
    savedStamp.diaryEntries = stamp.diaryEntries
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    savedStamp.photoIDs = photos.map(\.id)

    for photo in photos {
      try photo.data.write(to: photoURL(for: photo.id), options: .atomic)
    }

    var updatedStamps = stamps
    if let index = updatedStamps.firstIndex(where: { $0.id == stamp.id }) {
      updatedStamps[index] = savedStamp
    } else {
      updatedStamps.append(savedStamp)
    }

    let encodedStamps = try JSONEncoder().encode(updatedStamps)
    try encodedStamps.write(to: manifestURL, options: .atomic)
    stamps = updatedStamps

    let retainedPhotoIDs = Set(updatedStamps.flatMap(\.photoIDs))
    for stalePhotoID in Set(previousPhotoIDs).subtracting(retainedPhotoIDs) {
      try? FileManager.default.removeItem(at: photoURL(for: stalePhotoID))
    }
  }

  func delete(_ stamp: TravelStamp) throws {
    let updatedStamps = stamps.filter { $0.id != stamp.id }
    let encodedStamps = try JSONEncoder().encode(updatedStamps)
    try encodedStamps.write(to: manifestURL, options: .atomic)
    stamps = updatedStamps

    let retainedPhotoIDs = Set(updatedStamps.flatMap(\.photoIDs))
    for stalePhotoID in Set(stamp.photoIDs).subtracting(retainedPhotoIDs) {
      try? FileManager.default.removeItem(at: photoURL(for: stalePhotoID))
    }
  }

  private var manifestURL: URL {
    storageURL.appendingPathComponent("stamps.json")
  }

  private func photoURL(for id: UUID) -> URL {
    storageURL.appendingPathComponent("\(id.uuidString).jpg")
  }

  private func load() {
    guard let data = try? Data(contentsOf: manifestURL) else {
      return
    }

    stamps = (try? JSONDecoder().decode([TravelStamp].self, from: data)) ?? []
  }
}
