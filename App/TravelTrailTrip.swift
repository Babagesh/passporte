import Foundation
import CoreLocation

struct TravelTrailTrip {
  /// The sample journey used to demonstrate the Pro feature before any trips are stamped.
  static let japan = TravelTrailTrip(isSample: true)
  var isSample = false
  var stops: [TrailStop] = [
    TrailStop(id: 0, city: "Tokyo", day: 1, detail: "Arrival · A first evening in Shinjuku", latitude: 35.6762, longitude: 139.6503),
    TrailStop(id: 1, city: "Kamakura", day: 2, detail: "Coastal air & the Great Buddha", latitude: 35.3192, longitude: 139.5467),
    TrailStop(id: 2, city: "Tokyo", day: 3, detail: "Back to the city · Next stop, Kyoto", latitude: 35.6762, longitude: 139.6503),
    TrailStop(id: 3, city: "Kyoto", day: 4, detail: "Temple paths & an evening in Gion", latitude: 35.0116, longitude: 135.7681),
    TrailStop(id: 4, city: "Osaka", day: 5, detail: "Latest stop · Dotonbori after dark", latitude: 34.6937, longitude: 135.5023)
  ]
  var citiesVisited: Int { Set(stops.map(\.city)).count }
  var distance = "~620 km"
  var totalDays = 9
}

struct TrailStop: Identifiable {
  var id: Int
  var city: String
  var day: Int
  var detail: String
  var latitude: Double
  var longitude: Double
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
