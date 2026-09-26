import SwiftUI
import MapKit

struct TrailMapPage: View {
  var selectedStop: Int
  var posture: String
  var hingeAngle: Double?
  var isFolded = false
  private let trip = TravelTrailTrip.japan
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("JAPAN / 日本").font(.caption.weight(.bold)).tracking(3)
        Spacer()
        Text("01").font(.caption)
      }
      Text("A trail worth keeping.")
        .font(.title.weight(.semibold))
      Map(initialPosition: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.3, longitude: 137.6),
        span: MKCoordinateSpan(latitudeDelta: 3.3, longitudeDelta: 6.0))), interactionModes: [.pan, .zoom]) {
          MapPolyline(coordinates: trip.stops.map(\.coordinate))
            .stroke(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
          MapPolyline(coordinates: Array(trip.stops.prefix(selectedStop + 1)).map(\.coordinate))
            .stroke(TrailStyle.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
          ForEach(trip.stops.filter { $0.id != 2 }) { stop in
            Annotation(stop.city, coordinate: stop.coordinate, anchor: .bottom) {
              Circle().fill(TrailStyle.ink).frame(width: 10, height: 10)
                .padding(5).background(.regularMaterial, in: Circle())
            }
          }
          Annotation("Day \(trip.stops[selectedStop].day)", coordinate: trip.stops[selectedStop].coordinate) {
            Circle().strokeBorder(TrailStyle.ink, lineWidth: 3)
              .frame(width: 38, height: 38)
              .background(TrailStyle.ink.opacity(0.18), in: Circle())
              .accessibilityLabel("Selected stop: \(trip.stops[selectedStop].city)")
          }
      }
      .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: selectedStop)
      .accessibilityLabel("Japan route: Tokyo, Kamakura, Tokyo, Kyoto, Osaka")
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text("DAY \(trip.stops[selectedStop].day)").font(.caption2.weight(.bold)).tracking(2)
          Text(trip.stops[selectedStop].city).font(.title2)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
          Text(posture).font(.caption)
          if let hingeAngle {
            Text("\(hingeAngle, specifier: "%.0f")° fold").font(.caption.monospacedDigit())
          }
        }.foregroundStyle(.secondary)
      }
      Text("Sample journey · Route is illustrative")
        .font(.caption2).foregroundStyle(.secondary)
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TrailStyle.page)
    .overlay(alignment: .trailing) {
      LinearGradient(colors: [.clear, .black.opacity(isFolded ? min(0.18, max(0, (180 - (hingeAngle ?? 180)) / 600)) : 0)], startPoint: .leading, endPoint: .trailing)
        .frame(width: 24).allowsHitTesting(false).accessibilityHidden(true)
    }
  }
}
