import SwiftUI
import MapKit

struct TrailMapPage: View {
  var trip: TravelTrailTrip
  var selectedStop: Int
  var posture: String
  var hingeAngle: Double?
  var isFolded = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var stop: TrailStop? {
    guard !trip.stops.isEmpty else {
      return nil
    }

    return trip.stops[min(max(selectedStop, 0), trip.stops.count - 1)]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(trip.headline).font(.caption.weight(.bold)).tracking(3)
        Spacer()
        Text("01").font(.caption)
      }
      Text("A trail worth keeping.")
        .font(.title.weight(.semibold))

      if let stop {
        Map(initialPosition: .region(trip.region), interactionModes: [.pan, .zoom]) {
          MapPolyline(coordinates: trip.stops.map(\.coordinate))
            .stroke(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
          MapPolyline(coordinates: Array(trip.stops.prefix(selectedStop + 1)).map(\.coordinate))
            .stroke(TrailStyle.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
          ForEach(trip.stops) { stop in
            Annotation(stop.city, coordinate: stop.coordinate, anchor: .bottom) {
              Circle().fill(TrailStyle.ink).frame(width: 10, height: 10)
                .padding(5).background(.regularMaterial, in: Circle())
            }
          }
          Annotation("Day \(stop.day)", coordinate: stop.coordinate) {
            Circle().strokeBorder(TrailStyle.ink, lineWidth: 3)
              .frame(width: 38, height: 38)
              .background(TrailStyle.ink.opacity(0.18), in: Circle())
              .accessibilityLabel("Selected stop: \(stop.city)")
          }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: selectedStop)
        .accessibilityLabel("Route: \(trip.routeDescription)")

        HStack(alignment: .firstTextBaseline) {
          VStack(alignment: .leading, spacing: 4) {
            Text("DAY \(stop.day)").font(.caption2.weight(.bold)).tracking(2)
            Text(stop.city).font(.title2)
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 4) {
            Text(posture).font(.caption)
            if let hingeAngle {
              Text("\(hingeAngle, specifier: "%.0f")° fold").font(.caption.monospacedDigit())
            }
          }.foregroundStyle(.secondary)
        }

        Text("Route drawn from the stamps in this passport")
          .font(.caption2).foregroundStyle(.secondary)
      } else {
        ContentUnavailableView(
          "No stamps yet",
          systemImage: "map",
          description: Text("Stamp a trip into this passport and your trail will appear here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
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
