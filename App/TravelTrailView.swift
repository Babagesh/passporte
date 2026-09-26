import SwiftUI

@available(iOS 27.1, *)
struct TravelTrailView: View {
  @Bindable var purchases: PurchaseStore
  var trip: TravelTrailTrip
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var selectedStop = 0
  @State private var isPlaying = false
  @State private var hingeAngle: Double?
  @State private var isFolded = false
  @State private var showsDemoSettings = false

  var body: some View {
    NavigationStack {
      Group {
        if purchases.hasTravelTrailAccess {
          TravelTrailSpread(trip: trip, selectedStop: $selectedStop, isPlaying: $isPlaying,
                            hingeAngle: hingeAngle, isFolded: isFolded)
        } else {
          ScrollView {
            VStack(spacing: 24) {
              Image(systemName: "lock.fill").font(.largeTitle)
              Text("Your next chapter awaits.")
                .font(.largeTitle.weight(.semibold))
              Text("Travel Trail Pass is locked in this demo. Unlock the demo pass to explore your Japan journey.")
                .multilineTextAlignment(.center)
              Button("Unlock Demo Pass") { purchases.demoTrailPassUnlocked = true }
                .buttonStyle(.borderedProminent)
              Text("No payment required. Your US passport and visa information remain free.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(32).frame(maxWidth: .infinity)
          }
        }
      }
      .background(TrailStyle.paper)
      .navigationTitle("Travel Trail")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark") { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Demo", systemImage: "sparkles") { showsDemoSettings = true }
        }
      }
      .sheet(isPresented: $showsDemoSettings) {
        NavigationStack {
          Form {
            Section("Travel Trail Pass · Demo") {
              Toggle("Pass unlocked", isOn: $purchases.demoTrailPassUnlocked)
              Text("This local override demonstrates locked and unlocked access. It does not make a purchase or change your RevenueCat account.")
                .font(.footnote).foregroundStyle(.secondary)
            }
            Section("RevenueCat") {
              LabeledContent("SDK", value: purchases.isConfigured ? "Configured" : "Not configured")
              LabeledContent("Travel Trail entitlement", value: purchases.hasRevenueCatTravelTrailPass ? "Active" : "Not active")
              Text("Demo mode uses the switch above. Live entitlement updates are observed separately from RevenueCat.")
                .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
              Text("Core US passport and visa information is always free.")
            }
          }
          .navigationTitle("Demo access")
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") { showsDemoSettings = false }
            }
          }
        }
      }
      .onHingeChange { _, context in
        hingeAngle = context.hinge?.angle.degrees
        isFolded = context.hinge?.status == .partiallyOpen
      }
      .onChange(of: purchases.demoTrailPassUnlocked) { _, _ in isPlaying = false }
      .task {
        selectedStop = max(trip.stops.count - 1, 0)
        if purchases.hasTravelTrailAccess && !reduceMotion && trip.stops.count > 1 { isPlaying = true }
      }
      .task(id: isPlaying) {
        guard isPlaying else { return }
        selectedStop = 0
        guard trip.stops.count > 1 else { return }
        for index in 1..<trip.stops.count {
          do { try await Task.sleep(for: .seconds(1.4)) } catch { return }
          guard !Task.isCancelled, purchases.hasTravelTrailAccess else { return }
          withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) { selectedStop = index }
        }
        isPlaying = false
      }
    }
    .tint(TrailStyle.ink)
  }
}

enum TrailStyle {
  static let paper = Color(uiColor: .systemGroupedBackground)
  static let page = Color(uiColor: .secondarySystemGroupedBackground)
  static let ink = Color.accentColor
}

@available(iOS 27.1, *)
private struct TravelTrailSpread: View {
  var trip: TravelTrailTrip
  @Binding var selectedStop: Int
  @Binding var isPlaying: Bool
  var hingeAngle: Double?
  var isFolded: Bool

  var body: some View {
    GeometryReader { geometry in
      // A sheet can be displaced entirely onto one side of the hinge. Only
      // split at a division when both resulting pages have usable local space.
      let division = geometry.reservedRegions(kind: .division).first { region in
        if region.frame.width > region.frame.height {
          return region.frame.minY - region.margins.top >= 180 &&
            geometry.size.height - region.frame.maxY - region.margins.bottom >= 180
        }
        return region.frame.minX - region.margins.leading >= 240 &&
          geometry.size.width - region.frame.maxX - region.margins.trailing >= 240
      }
      let tabletop = division.map { $0.frame.width > $0.frame.height } ?? false
      let shadow = isFolded ? min(0.22, max(0.04, (180 - (hingeAngle ?? 180)) / 700)) : 0.025
      if let division {
        let gap = division.frame
        ZStack(alignment: .topLeading) {
          TrailMapPage(trip: trip, selectedStop: selectedStop, posture: tabletop ? "Tabletop" : "Book", hingeAngle: hingeAngle, isFolded: isFolded)
            .frame(width: tabletop ? geometry.size.width : max(0, gap.minX - division.margins.leading),
                   height: tabletop ? max(0, gap.minY - division.margins.top) : geometry.size.height)
          TrailTimelinePage(trip: trip, selectedStop: $selectedStop, isPlaying: $isPlaying)
            .frame(width: tabletop ? geometry.size.width : max(0, geometry.size.width - gap.maxX - division.margins.trailing),
                   height: tabletop ? max(0, geometry.size.height - gap.maxY - division.margins.bottom) : geometry.size.height)
            .offset(x: tabletop ? 0 : gap.maxX + division.margins.trailing,
                    y: tabletop ? gap.maxY + division.margins.bottom : 0)
        }
        .background(.black.opacity(shadow))
      } else if geometry.size.width >= 600 {
        HStack(spacing: 2) {
          TrailMapPage(trip: trip, selectedStop: selectedStop, posture: "Passport spread", hingeAngle: hingeAngle, isFolded: isFolded)
          TrailTimelinePage(trip: trip, selectedStop: $selectedStop, isPlaying: $isPlaying)
        }
        .background(.black.opacity(shadow))
      } else {
        ScrollView {
          VStack(spacing: 12) {
            TrailMapPage(trip: trip, selectedStop: selectedStop, posture: "Pocket view", hingeAngle: hingeAngle, isFolded: isFolded)
              .frame(height: 380)
            TrailTimelinePage(trip: trip, selectedStop: $selectedStop, isPlaying: $isPlaying)
              .frame(minHeight: 680)
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(8)
  }
}
