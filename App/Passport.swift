import Foundation

struct Passport: Identifiable {
  let id = UUID()
  var title: String
  var detail: String
  var pages: [PassportPage] = PassportPage.startingStock

  /// The first page with room for another stamp, or nil once the passport is full.
  var firstPageWithRoom: Int? {
    pages.firstIndex { !$0.isFull }
  }

  static let sample = Passport(title: "United States", detail: "Sample passport")
}

struct PassportPage: Identifiable {
  /// Stamps that fit on one page before it needs a fresh one.
  static let stampCapacity = 4
  static let startingCount = 10

  static var startingStock: [PassportPage] {
    (0..<startingCount).map { _ in PassportPage() }
  }

  let id = UUID()
  /// Stamps stamped onto this page, stored by id since the stamp book owns the stamps themselves.
  var stampIDs: [UUID] = []

  var isFull: Bool {
    stampIDs.count >= Self.stampCapacity
  }
}
