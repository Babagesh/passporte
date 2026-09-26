import SwiftUI

struct VisaStampArtwork: View {
  var stamp: TravelStamp
  var tilt: Double
  var height: CGFloat = 126

  private var typeScale: CGFloat {
    min(1, max(0.7, height / 110))
  }

  private var design: VisaStampDesign {
    switch stamp.country {
    case .japan:
      VisaStampDesign(ink: Color(red: 0.72, green: 0.13, blue: 0.16), shape: .round, motif: "sun.max.fill", heading: "LANDING PERMISSION")
    case .france:
      VisaStampDesign(ink: Color(red: 0.13, green: 0.26, blue: 0.49), shape: .rectangle, motif: "building.classical.columns.fill", heading: "RÉPUBLIQUE FRANÇAISE")
    case .italy:
      VisaStampDesign(ink: Color(red: 0.16, green: 0.40, blue: 0.32), shape: .round, motif: "building.classical.columns.fill", heading: "CONTROLLO PASSAPORTI")
    case .unitedStates:
      VisaStampDesign(ink: Color(red: 0.12, green: 0.22, blue: 0.42), shape: .oval, motif: "star.fill", heading: "UNITED STATES · ENTRY")
    case .canada:
      VisaStampDesign(ink: Color(red: 0.70, green: 0.17, blue: 0.19), shape: .rectangle, motif: "leaf.fill", heading: "CANADA · ADMITTED")
    case .unitedKingdom:
      VisaStampDesign(ink: Color(red: 0.33, green: 0.24, blue: 0.47), shape: .round, motif: "crown.fill", heading: "UNITED KINGDOM")
    case .australia:
      VisaStampDesign(ink: Color(red: 0.10, green: 0.32, blue: 0.49), shape: .oval, motif: "water.waves", heading: "AUSTRALIA · ARRIVAL")
    case .newZealand:
      VisaStampDesign(ink: Color(red: 0.19, green: 0.38, blue: 0.31), shape: .rectangle, motif: "mountain.2.fill", heading: "NEW ZEALAND · ENTRY")
    case .spain:
      VisaStampDesign(ink: Color(red: 0.66, green: 0.27, blue: 0.12), shape: .round, motif: "sun.max.fill", heading: "ESPAÑA · ENTRADA")
    case .thailand:
      VisaStampDesign(ink: Color(red: 0.38, green: 0.27, blue: 0.51), shape: .round, motif: "globe.asia.australia.fill", heading: "IMMIGRATION BUREAU")
    case .india:
      VisaStampDesign(ink: Color(red: 0.62, green: 0.27, blue: 0.14), shape: .rectangle, motif: "globe.asia.australia.fill", heading: "BHARAT · ENTRY")
    case .southKorea:
      VisaStampDesign(ink: Color(red: 0.17, green: 0.30, blue: 0.55), shape: .round, motif: "globe.asia.australia.fill", heading: "REPUBLIC OF KOREA")
    case .portugal:
      VisaStampDesign(ink: Color(red: 0.12, green: 0.40, blue: 0.38), shape: .rectangle, motif: "building.classical.columns.fill", heading: "PORTUGAL · ENTRADA")
    case .iceland:
      VisaStampDesign(ink: Color(red: 0.15, green: 0.34, blue: 0.51), shape: .rectangle, motif: "water.waves", heading: "ICELAND · ENTRY")
    }
  }

  var body: some View {
    ZStack {
      VisaStampOutline(shape: design.shape, ink: design.ink)

      VStack(spacing: 4) {
        Text(design.heading)
          .font(.system(size: 7 * typeScale, weight: .bold, design: .rounded))
          .tracking(0.8)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        HStack(spacing: 7) {
          Rectangle()
            .frame(height: 0.7)
          Image(systemName: design.motif)
            .font(.system(size: 15 * typeScale, weight: .semibold))
          Rectangle()
            .frame(height: 0.7)
        }
        .padding(.horizontal, 4)

        Text(stamp.country.displayName.uppercased())
          .font(.system(size: 10 * typeScale, weight: .black, design: .serif))
          .tracking(0.7)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        Text("\(stamp.entryDate.formatted(.dateTime.day().month(.abbreviated)))  ·  \(stamp.exitDate.formatted(.dateTime.day().month(.abbreviated)))")
          .font(.system(size: 7 * typeScale, weight: .semibold, design: .monospaced))
          .lineLimit(1)
          .minimumScaleFactor(0.65)

        if !stamp.photoIDs.isEmpty {
          Label("\(stamp.photoIDs.count)", systemImage: "photo")
            .font(.system(size: 7 * typeScale, weight: .semibold))
            .labelStyle(.titleAndIcon)
        }
      }
      .foregroundStyle(design.ink)
      .padding(12 * typeScale)
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .rotationEffect(.degrees(tilt))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(stamp.country.displayName) visa stamp")
    .accessibilityValue("\(stamp.entryDate.formatted(date: .abbreviated, time: .omitted)) to \(stamp.exitDate.formatted(date: .abbreviated, time: .omitted))")
  }
}

private struct VisaStampDesign {
  var ink: Color
  var shape: VisaStampShape
  var motif: String
  var heading: String
}

private enum VisaStampShape {
  case round
  case oval
  case rectangle
}

private struct VisaStampOutline: View {
  var shape: VisaStampShape
  var ink: Color

  @ViewBuilder
  var body: some View {
    switch shape {
    case .round:
      ZStack {
        Circle()
          .stroke(ink.opacity(0.78), lineWidth: 1.8)
          .padding(3)
        Circle()
          .stroke(ink.opacity(0.68), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
          .padding(8)
      }
      .aspectRatio(1, contentMode: .fit)
    case .oval:
      ZStack {
        Ellipse()
          .stroke(ink.opacity(0.78), lineWidth: 1.8)
          .padding(3)
        Ellipse()
          .stroke(ink.opacity(0.68), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
          .padding(8)
      }
      .aspectRatio(1.35, contentMode: .fit)
    case .rectangle:
      ZStack {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .stroke(ink.opacity(0.78), lineWidth: 1.8)
          .padding(3)
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .stroke(ink.opacity(0.68), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
          .padding(8)
      }
      .padding(.horizontal, 4)
    }
  }
}
