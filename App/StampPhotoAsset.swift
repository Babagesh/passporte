import Foundation
import UIKit

struct StampPhotoAsset: Identifiable {
  var id: UUID
  var data: Data

  init(id: UUID = UUID(), data: Data) {
    self.id = id
    self.data = data
  }

  var image: UIImage? {
    UIImage(data: data)
  }

  static func compressed(from image: UIImage, id: UUID = UUID()) -> StampPhotoAsset? {
    guard
      let thumbnail = image.preparingThumbnail(of: CGSize(width: 1_600, height: 1_600)),
      let data = thumbnail.jpegData(compressionQuality: 0.78)
    else {
      return nil
    }

    return StampPhotoAsset(id: id, data: data)
  }

  static func compressed(from data: Data) -> StampPhotoAsset? {
    guard let image = UIImage(data: data) else {
      return nil
    }

    return compressed(from: image)
  }
}
