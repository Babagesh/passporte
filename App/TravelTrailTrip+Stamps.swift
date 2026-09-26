import CoreLocation
import Foundation
import MapKit

extension TravelTrailTrip {
  /// The passport's own trail, or the sample journey so Pro still demos before any trips are stamped.
  static func trail(for stamps: [TravelStamp]) -> TravelTrailTrip {
    stamps.isEmpty ? .japan : TravelTrailTrip(stamps: stamps)
  }

  /// Builds the trail from a passport's visa stamps, earliest arrival first.
  init(stamps: [TravelStamp]) {
    let ordered = stamps.sorted { $0.entryDate < $1.entryDate }
    let calendar = Calendar.current
    let firstDay = ordered.first.map { calendar.startOfDay(for: $0.entryDate) }

    stops = ordered.enumerated().map { index, stamp in
      let place = stamp.country.trailPlace
      let dayOffset = firstDay.flatMap { start in
        calendar.dateComponents(
          [.day],
          from: start,
          to: calendar.startOfDay(for: stamp.entryDate)
        ).day
      } ?? 0

      return TrailStop(
        id: index,
        city: place.city,
        day: dayOffset + 1,
        detail: stamp.trailDetail,
        latitude: place.latitude,
        longitude: place.longitude
      )
    }

    totalDays = Self.dayCount(of: ordered)
    distance = Self.formattedDistance(along: stops)
  }

  /// Caption for the page header: one country reads as itself, several as a count.
  var headline: String {
    let cities = Set(stops.map(\.city))

    if stops.isEmpty {
      return "TRAVEL TRAIL"
    }

    if cities.count == 1, let city = cities.first {
      return city.uppercased()
    }

    return "\(cities.count) STOPS"
  }

  var routeDescription: String {
    stops.map(\.city).joined(separator: ", ")
  }

  /// A region that frames every stop, with a little breathing room.
  var region: MKCoordinateRegion {
    let latitudes = stops.map(\.latitude)
    let longitudes = stops.map(\.longitude)

    guard
      let minLatitude = latitudes.min(),
      let maxLatitude = latitudes.max(),
      let minLongitude = longitudes.min(),
      let maxLongitude = longitudes.max()
    else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 160)
      )
    }

    return MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: (minLatitude + maxLatitude) / 2,
        longitude: (minLongitude + maxLongitude) / 2
      ),
      span: MKCoordinateSpan(
        latitudeDelta: max((maxLatitude - minLatitude) * 1.6, 3),
        longitudeDelta: max((maxLongitude - minLongitude) * 1.6, 5)
      )
    )
  }

  private static func dayCount(of stamps: [TravelStamp]) -> Int {
    guard
      let start = stamps.map(\.entryDate).min(),
      let end = stamps.map(\.exitDate).max()
    else {
      return 0
    }

    let calendar = Calendar.current
    let days = calendar.dateComponents(
      [.day],
      from: calendar.startOfDay(for: start),
      to: calendar.startOfDay(for: end)
    ).day ?? 0

    return days + 1
  }

  private static func formattedDistance(along stops: [TrailStop]) -> String {
    guard stops.count > 1 else {
      return "—"
    }

    let metres = zip(stops, stops.dropFirst()).reduce(into: 0.0) { total, pair in
      let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
      let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
      total += from.distance(from: to)
    }

    let kilometres = (metres / 1_000).rounded()
    return "~\(kilometres.formatted(.number.precision(.fractionLength(0)))) km"
  }
}

extension TravelCountry {
  /// Where a stamp from this country lands on the map.
  var trailPlace: (city: String, latitude: Double, longitude: Double) {
    switch self {
    case .japan:
      ("Tokyo", 35.6762, 139.6503)
    case .france:
      ("Paris", 48.8566, 2.3522)
    case .italy:
      ("Rome", 41.9028, 12.4964)
    case .unitedStates:
      ("Washington, D.C.", 38.9072, -77.0369)
    case .canada:
      ("Ottawa", 45.4215, -75.6972)
    case .unitedKingdom:
      ("London", 51.5072, -0.1276)
    case .australia:
      ("Sydney", -33.8688, 151.2093)
    case .newZealand:
      ("Auckland", -36.8485, 174.7633)
    case .spain:
      ("Madrid", 40.4168, -3.7038)
    case .thailand:
      ("Bangkok", 13.7563, 100.5018)
    case .india:
      ("New Delhi", 28.6139, 77.2090)
    case .southKorea:
      ("Seoul", 37.5665, 126.9780)
    case .portugal:
      ("Lisbon", 38.7223, -9.1393)
    case .iceland:
      ("Reykjavík", 64.1466, -21.9426)
    }
  }
}

extension TravelStamp {
  /// The stamp's first diary note, falling back to its travel dates.
  var trailDetail: String {
    if let note = diaryEntries.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
      return note
    }

    return "\(entryDate.formatted(.dateTime.day().month(.abbreviated))) – \(exitDate.formatted(.dateTime.day().month(.abbreviated)))"
  }
}
