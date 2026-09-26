import SwiftUI

struct PassportVisaPageOverlay: View {
  var stamps: [TravelStamp]
  var pageNumber: Int
  var onSelectStamp: (TravelStamp) -> Void

  var body: some View {
    GeometryReader { geometry in
      let stampHeight = max(68, min(94, geometry.size.height * 0.115))
      let rowSpacing = max(3, geometry.size.height * 0.008)
      let pageHeight = stampHeight * 3 + rowSpacing * 2

      HStack(spacing: geometry.size.width * 0.05) {
        passportLeaf(
          stamps: Array(stamps.prefix(3)),
          isRightLeaf: false,
          height: stampHeight,
          spacing: rowSpacing
        )

        passportLeaf(
          stamps: Array(stamps.dropFirst(3)),
          isRightLeaf: true,
          height: stampHeight,
          spacing: rowSpacing
        )
      }
      .frame(width: geometry.size.width * 0.91, height: pageHeight)
      .position(x: geometry.size.width / 2, y: geometry.size.height * 0.38)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Visa page \(pageNumber)")
  }

  private func passportLeaf(
    stamps leafStamps: [TravelStamp],
    isRightLeaf: Bool,
    height: CGFloat,
    spacing: CGFloat
  ) -> some View {
    VStack(spacing: spacing) {
      if leafStamps.isEmpty && isRightLeaf {
        Label("Add stamp from the toolbar", systemImage: "plus")
          .font(.caption2.weight(.medium))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ForEach(Array(leafStamps.enumerated()), id: \.element.id) { index, stamp in
          Button {
            onSelectStamp(stamp)
          } label: {
            VisaStampArtwork(
              stamp: stamp,
              tilt: Double((index % 3) - 1) * 1.1,
              height: height
            )
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityHint("Opens this visa stamp's travel notes and photos")
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}
