import SwiftUI

enum ScrapbookPalette {
  static let paper = Color(red: 0.98, green: 0.95, blue: 0.88)
  static let paperEdge = Color(red: 0.93, green: 0.88, blue: 0.77)
  static let board = Color(red: 0.89, green: 0.82, blue: 0.70)
  static let ink = Color(red: 0.24, green: 0.17, blue: 0.11)
  static let inkSoft = Color(red: 0.45, green: 0.35, blue: 0.25)
  static let accent = Color(red: 0.70, green: 0.31, blue: 0.16)
  static let tape = Color(red: 0.95, green: 0.84, blue: 0.56)
}

/// The cork-and-paper backdrop the stamp editor is pasted onto.
struct ScrapbookBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [ScrapbookPalette.board, ScrapbookPalette.paperEdge],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      RadialGradient(
        colors: [.white.opacity(0.35), .clear],
        center: .topLeading,
        startRadius: 12,
        endRadius: 620
      )
    }
    .ignoresSafeArea()
  }
}

/// A paper card taped onto the page, with a heavy hand-inked border.
struct ScrapbookCard<Content: View>: View {
  var title: String
  var symbol: String
  var tilt: Double = 0
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 7) {
        Image(systemName: symbol)
          .font(.system(size: 12, weight: .bold))

        Text(title.uppercased())
          .font(.system(size: 11, weight: .black, design: .rounded))
          .tracking(2.2)

        Spacer(minLength: 0)
      }
      .foregroundStyle(ScrapbookPalette.accent)

      content
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ScrapbookPalette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(ScrapbookPalette.ink.opacity(0.8), lineWidth: 2.5)
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(ScrapbookPalette.inkSoft.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        .padding(7)
    }
    .overlay(alignment: .topLeading) {
      WashiTape()
        .offset(x: 14, y: -11)
    }
    .shadow(color: ScrapbookPalette.ink.opacity(0.2), radius: 9, x: 3, y: 6)
    .rotationEffect(.degrees(tilt))
  }
}

struct WashiTape: View {
  var width: CGFloat = 64
  var tilt: Double = -6

  var body: some View {
    Rectangle()
      .fill(ScrapbookPalette.tape.opacity(0.85))
      .frame(width: width, height: 22)
      .overlay {
        Rectangle()
          .stroke(.white.opacity(0.5), lineWidth: 0.8)
      }
      .rotationEffect(.degrees(tilt))
      .shadow(color: ScrapbookPalette.ink.opacity(0.18), radius: 2, x: 1, y: 1)
      .accessibilityHidden(true)
  }
}

/// A dashed cut line used to separate entries inside a card.
struct ScrapbookCutLine: View {
  var body: some View {
    Rectangle()
      .fill(.clear)
      .frame(height: 1)
      .overlay {
        Rectangle()
          .stroke(ScrapbookPalette.inkSoft.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
      }
      .accessibilityHidden(true)
  }
}
