import SwiftUI

struct TrailTimelinePage: View {
  var trip: TravelTrailTrip
  @Binding var selectedStop: Int
  @Binding var isPlaying: Bool

  private var currentStop: TrailStop? {
    guard !trip.stops.isEmpty else {
      return nil
    }

    return trip.stops[min(max(selectedStop, 0), trip.stops.count - 1)]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        HStack {
          Text("TRAVEL TRAIL PASS").font(.caption.weight(.bold)).tracking(2)
          Spacer()
          Text("02").font(.caption)
        }
        HStack(alignment: .firstTextBaseline) {
          Text(trip.isSample ? "A sample chapter" : "Your travel chapter")
            .font(.title.weight(.semibold))
          Spacer()
          if !trip.stops.isEmpty {
            Text(trip.isSample ? "SAMPLE TRIP" : "ACTIVE TRIP")
              .font(.caption2.bold())
              .foregroundStyle(TrailStyle.ink)
          }
        }

        if trip.stops.isEmpty {
          Text("Stamp a trip into this passport and it will be plotted here, in the order you travelled.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          TrailTripStats(
            cities: trip.citiesVisited,
            distance: trip.distance,
            currentDay: currentStop?.day ?? 1,
            totalDays: trip.totalDays
          )
          VStack(alignment: .leading, spacing: 4) {
            Text("LATEST STOP").font(.caption2.bold()).tracking(2).foregroundStyle(.secondary)
            Text(trip.stops.last?.city ?? "—").font(.largeTitle.weight(.medium))
          }
          Divider()
          HStack {
            Text("The journey so far").font(.headline)
            Spacer()
            Button(isPlaying ? "Pause" : "Replay", systemImage: isPlaying ? "pause.fill" : "play.fill") {
              isPlaying.toggle()
            }
            .buttonStyle(.bordered)
            .disabled(trip.stops.count < 2)
          }
          VStack(spacing: 6) {
            ForEach(trip.stops) { stop in
              Button {
                isPlaying = false
                selectedStop = stop.id
              } label: {
                HStack(alignment: .top, spacing: 14) {
                  Text(String(format: "%02d", stop.day))
                    .font(.headline.monospacedDigit())
                    .frame(width: 36, height: 36)
                    .background(TrailStyle.ink.opacity(0.1), in: Circle())
                  VStack(alignment: .leading, spacing: 5) {
                    Text(stop.city).font(.headline)
                    Text(stop.detail).font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer(minLength: 0)
                  if selectedStop == stop.id {
                    Circle().fill(TrailStyle.ink).frame(width: 7, height: 7).padding(.top, 12)
                  }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(selectedStop == stop.id ? TrailStyle.ink.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityLabel("Day \(stop.day), \(stop.city), \(stop.detail)")
              .accessibilityAddTraits(selectedStop == stop.id ? .isSelected : [])
            }
          }
        }

        Text("Demo pass unlocked · No payment required")
          .font(.caption).foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(TrailStyle.page)
  }
}

private struct TrailTripStats: View {
  var cities: Int
  var distance: String
  var currentDay: Int
  var totalDays: Int

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .top, spacing: 20) {
        TrailStat(value: "\(cities)", label: cities == 1 ? "stop visited" : "stops visited")
        TrailStat(value: distance, label: "traveled")
        TrailStat(value: "\(currentDay) of \(totalDays)", label: "days · active trip")
      }
      VStack(alignment: .leading, spacing: 12) {
        TrailStat(value: "\(cities) stops", label: "visited")
        TrailStat(value: distance, label: "traveled")
        TrailStat(value: "Day \(currentDay) of \(totalDays)", label: "active trip")
      }
    }
  }
}

private struct TrailStat: View {
  var value: String
  var label: String
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(value).font(.title2.weight(.semibold)).fixedSize(horizontal: true, vertical: false)
      Text(label).font(.caption).foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}
