import Foundation

enum TravelCountry: String, CaseIterable, Codable, Identifiable {
  case japan = "JP"
  case france = "FR"
  case italy = "IT"
  case unitedStates = "US"
  case canada = "CA"
  case unitedKingdom = "GB"
  case australia = "AU"
  case newZealand = "NZ"
  case spain = "ES"
  case thailand = "TH"
  case india = "IN"
  case southKorea = "KR"
  case portugal = "PT"
  case iceland = "IS"

  var id: String {
    rawValue
  }

  var displayName: String {
    Locale.current.localizedString(forRegionCode: rawValue) ?? rawValue
  }
}

struct TravelStamp: Codable, Equatable, Identifiable {
  var id: UUID
  var country: TravelCountry
  var entryDate: Date
  var exitDate: Date
  var diaryEntries: [String]
  var photoIDs: [UUID]

  init(
    id: UUID = UUID(),
    country: TravelCountry = .japan,
    entryDate: Date = .now,
    exitDate: Date = .now,
    diaryEntries: [String] = [],
    photoIDs: [UUID] = []
  ) {
    self.id = id
    self.country = country
    self.entryDate = entryDate
    self.exitDate = exitDate
    self.diaryEntries = diaryEntries
    self.photoIDs = photoIDs
  }
}
