import SwiftUI
import UIKit

struct PassportsView: View {
  var store: StampBookStore
  var purchases: PurchaseStore

  @State private var passports: [Passport] = [.sample]
  @State private var presentedPassportID: Passport.ID?
  @State private var isShowingNewPassport = false

  private var presentedIndex: Int? {
    passports.firstIndex { $0.id == presentedPassportID }
  }

  private var isShowingPassport: Binding<Bool> {
    Binding {
      presentedPassportID != nil
    } set: { isPresented in
      if !isPresented {
        presentedPassportID = nil
      }
    }
  }

  var body: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 20)],
        spacing: 24
      ) {
        ForEach(passports) { passport in
          Button {
            presentedPassportID = passport.id
          } label: {
            PassportCover(passport: passport)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(passport.title) passport")
          .accessibilityHint("Opens the passport cover. On iPhone Duo's larger display, shows the inside pages.")
          .contextMenu {
            Button(role: .destructive) {
              passports.removeAll { $0.id == passport.id }
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
      .frame(maxWidth: 720, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .padding(20)
      .padding(.bottom, 72)
    }
    .overlay {
      if passports.isEmpty {
        ContentUnavailableView(
          WorkspaceDestination.passports.emptyTitle,
          systemImage: WorkspaceDestination.passports.symbol,
          description: Text(WorkspaceDestination.passports.emptyMessage)
        )
      }
    }
    .navigationTitle("Passports")
    .overlay(alignment: .bottomTrailing) {
      Button {
        isShowingNewPassport = true
      } label: {
        PassportCircleBadge(systemImage: "plus")
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Create passport")
      .accessibilityHint("Adds a passport to your library.")
      .padding(24)
    }
    .sheet(isPresented: $isShowingNewPassport) {
      NewPassportView { passport in
        passports.append(passport)
      }
    }
    .fullScreenCover(isPresented: isShowingPassport) {
      if let presentedIndex {
        NavigationStack {
          PassportDetailView(
            passport: $passports[presentedIndex],
            store: store,
            purchases: purchases
          )
        }
      }
    }
  }
}

private struct PassportCover: View {
  var passport: Passport

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      PassportArtwork(name: "USPassportCover") {
        USPassportCover()
      }
        .aspectRatio(0.72, contentMode: .fit)

      VStack(alignment: .leading, spacing: 3) {
        Text(passport.title)
          .font(.headline)
          .foregroundStyle(.primary)

        Text(passport.detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

private struct NewPassportView: View {
  var create: (Passport) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @State private var detail = ""

  private var trimmedTitle: String {
    title.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Name", text: $title)
          TextField("Description", text: $detail)
        } footer: {
          Text("New passports use the United States cover artwork.")
        }
      }
      .navigationTitle("New Passport")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            create(
              Passport(
                title: trimmedTitle,
                detail: trimmedDetail.isEmpty ? "United States passport" : trimmedDetail
              )
            )
            dismiss()
          }
          .disabled(trimmedTitle.isEmpty)
        }
      }
    }
  }
}

private struct PassportDetailView: View {
  @Binding var passport: Passport
  var store: StampBookStore
  var purchases: PurchaseStore

  @State private var showsTravelTrail = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.dismiss) private var dismiss
  @State private var pageIndex = 0
  @State private var stampBeingEdited: TravelStamp?
  @State private var stampIDsBeforeEditing: Set<UUID> = []
  @State private var selectedStampID: UUID?
  /// Details sit on the leaf opposite the stamp, so the stamp stays visible.
  @State private var detailsEdge: Edge = .trailing
  @State private var isDetailsFullScreen = false
  @State private var stampToEditAfterDismissal: TravelStamp?

  /// The passport stays closed while the Duo is folded, so only its cover shows.
  private var isShut: Bool {
    horizontalSizeClass != .regular
  }

  private var selectedStamp: TravelStamp? {
    guard let selectedStampID else {
      return nil
    }

    return store.stamps.first { $0.id == selectedStampID }
  }

  /// Every stamp in this passport, in the order it was pasted in.
  private var trailStamps: [TravelStamp] {
    passport.pages.flatMap(\.stampIDs).compactMap { stampID in
      store.stamps.first { $0.id == stampID }
    }
  }

  var body: some View {
    Group {
      if isShut {
        PassportCoverView()
          .ignoresSafeArea()
          .background(PassportPalette.coverNavy.ignoresSafeArea())
          .transition(.opacity)
      } else {
        PassportPageFlipper(pageCount: passport.pages.count, index: $pageIndex) { index in
          PassportSpreadView(
            page: passport.pages[index],
            store: store,
            onSelectStamp: select
          )
        }
        .ignoresSafeArea()
        .background(PassportPalette.paperShadow.ignoresSafeArea())
        .overlay(alignment: detailsEdge == .leading ? .leading : .trailing) {
          if let stamp = selectedStamp, !isDetailsFullScreen {
            StampDetailsPanel(
              stamp: stamp,
              store: store,
              onClose: { selectedStampID = nil },
              onExpand: { isDetailsFullScreen = true },
              onEdit: { edit(stamp) }
            )
            .frame(width: 380)
            .frame(maxHeight: .infinity)
            .transition(.move(edge: detailsEdge).combined(with: .opacity))
          }
        }
        .animation(reduceMotion ? nil : .smooth, value: selectedStampID)
        .transition(.opacity)
      }
    }
    .sheet(item: $stampBeingEdited, onDismiss: adoptNewStamps) { stamp in
      NavigationStack {
        StampEditorView(stamp: stamp, store: store)
      }
    }
    .fullScreenCover(isPresented: $isDetailsFullScreen, onDismiss: presentPendingEdit) {
      if let stamp = selectedStamp {
        StampDetailsPanel(
          stamp: stamp,
          store: store,
          onClose: { isDetailsFullScreen = false },
          onExpand: { },
          onEdit: {
            stampToEditAfterDismissal = stamp
            isDetailsFullScreen = false
          }
        )
      }
    }
    .sheet(isPresented: $showsTravelTrail) {
      if #available(iOS 27.1, *) {
        TravelTrailView(purchases: purchases, trip: .trail(for: trailStamps))
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
      }
    }
    .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: isShut)
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbarBackground(.hidden, for: .bottomBar)
    .toolbarColorScheme(isShut ? .dark : .light, for: .navigationBar)
    .toolbarColorScheme(isShut ? .dark : .light, for: .bottomBar)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close", systemImage: "xmark") {
          dismiss()
        }
        .labelStyle(.iconOnly)
      }

      if !isShut {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Travel Trail", systemImage: "map") {
            showsTravelTrail = true
          }
          .labelStyle(.iconOnly)
          .accessibilityHint("Opens the Japan trip map and timeline.")
        }

        ToolbarItemGroup(placement: .bottomBar) {
          Spacer()

          Button("Add stamp", systemImage: "plus") {
            addStamp()
          }
          .labelStyle(.iconOnly)
          .accessibilityHint("Stamps a trip onto the first page with room.")
        }
      }
    }
    .preferredColorScheme(isShut ? .dark : .light)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func addStamp() {
    stampIDsBeforeEditing = Set(store.stamps.map(\.id))
    stampBeingEdited = TravelStamp()
  }

  private func select(_ stamp: TravelStamp, on leaf: Edge) {
    selectedStampID = stamp.id
    detailsEdge = leaf == .leading ? .trailing : .leading
  }

  private func edit(_ stamp: TravelStamp) {
    stampIDsBeforeEditing = Set(store.stamps.map(\.id))
    stampBeingEdited = stamp
    selectedStampID = nil
  }

  private func presentPendingEdit() {
    guard let stamp = stampToEditAfterDismissal else {
      return
    }

    stampToEditAfterDismissal = nil
    edit(stamp)
  }

  /// Stamps whatever the editor saved onto the first page with room, binding in a
  /// fresh page only once every existing page is full.
  private func adoptNewStamps() {
    let newStampIDs = store.stamps.map(\.id).filter { !stampIDsBeforeEditing.contains($0) }
    stampIDsBeforeEditing = []

    guard !newStampIDs.isEmpty else {
      return
    }

    var landingPage = pageIndex

    for stampID in newStampIDs {
      let page: Int

      if let available = passport.firstPageWithRoom {
        page = available
      } else {
        passport.pages.append(PassportPage())
        page = passport.pages.count - 1
      }

      passport.pages[page].stampIDs.append(stampID)
      landingPage = page
    }

    withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) {
      pageIndex = landingPage
    }
  }
}

private struct PassportCircleBadge: View {
  var systemImage: String

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 22, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: 60, height: 60)
      .background(PassportPalette.coverBlue, in: Circle())
      .overlay {
        Circle()
          .stroke(.white.opacity(0.22), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
      .contentShape(Circle())
  }
}

private struct PassportCoverView: View {
  var body: some View {
    PassportArtwork(name: "USPassportCover") {
      USPassportCover(fillsScreen: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
  }
}

private struct PassportSpreadView: View {
  var page: PassportPage
  var store: StampBookStore
  var onSelectStamp: (TravelStamp, Edge) -> Void

  private var stamps: [TravelStamp] {
    page.stampIDs.compactMap { stampID in
      store.stamps.first { $0.id == stampID }
    }
  }

  var body: some View {
    PassportArtwork(name: "USPassportInterior", zoom: 1.06) {
      PassportInteriorSpread(fillsScreen: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay {
      StampPageLayout(stamps: stamps, onSelectStamp: onSelectStamp)
    }
    .clipped()
  }
}

/// Lays the page's stamps into a two-by-two grid, filling left to right.
private struct StampPageLayout: View {
  var stamps: [TravelStamp]
  var onSelectStamp: (TravelStamp, Edge) -> Void

  /// Hand-stamped pages are never square to the page.
  private let tilts: [Double] = [-6, 5, -3, 7]

  var body: some View {
    VStack(spacing: 18) {
      ForEach(0..<2, id: \.self) { row in
        HStack(spacing: 18) {
          ForEach(0..<2, id: \.self) { column in
            let slot = row * 2 + column

            if slot < stamps.count {
              let stamp = stamps[slot]

              Button {
                onSelectStamp(stamp, column == 0 ? .leading : .trailing)
              } label: {
                VisaStampArtwork(stamp: stamp, tilt: tilts[slot % 4], height: 132)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityHint("Opens this visa stamp's travel notes and photos")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
              Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
        }
      }
    }
    .padding(.horizontal, 28)
    .padding(.vertical, 56)
  }
}

/// Pages the passport like a book: dragging horizontally lifts the current page
/// off the spine and turns it over to reveal the page underneath.
private struct PassportPageFlipper<Page: View>: View {
  var pageCount: Int
  @Binding var index: Int
  var page: (Int) -> Page

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  /// Turn in progress: positive turns forward to the next page, negative turns back.
  @State private var turn: CGFloat = 0

  private var currentIndex: Int {
    clamped(index)
  }

  private var turningIndex: Int? {
    if turn > 0 {
      return currentIndex
    }

    if turn < 0, currentIndex > 0 {
      return currentIndex - 1
    }

    return nil
  }

  private var underlyingIndex: Int {
    turn > 0 ? clamped(currentIndex + 1) : currentIndex
  }

  private func clamped(_ index: Int) -> Int {
    min(max(index, 0), max(pageCount - 1, 0))
  }

  /// Degrees of the turning page about the spine: 0 lies flat, -180 is fully turned.
  private var turnAngle: Double {
    turn > 0 ? -180 * Double(turn) : -180 * Double(1 + turn)
  }

  var body: some View {
    GeometryReader { geometry in
      let width = max(geometry.size.width, 1)

      ZStack {
        page(underlyingIndex)
          .overlay {
            // Shadow cast by the lifted page onto the one beneath it.
            LinearGradient(
              colors: [.black.opacity(0.35), .clear],
              startPoint: .leading,
              endPoint: .trailing
            )
            .opacity(turn == 0 ? 0 : 0.6)
            .allowsHitTesting(false)
          }

        if let turningIndex {
          page(turningIndex)
            .overlay {
              LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0.05)],
                startPoint: .trailing,
                endPoint: .leading
              )
              .opacity(min(abs(turnAngle) / 180, 1))
              .allowsHitTesting(false)
            }
            .rotation3DEffect(
              .degrees(turnAngle),
              axis: (x: 0, y: 1, z: 0),
              anchor: .leading,
              perspective: 0.45
            )
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .clipped()
      .contentShape(Rectangle())
      .gesture(pageTurn(width: width))
    }
    .accessibilityElement(children: .contain)
  }

  private func pageTurn(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        turn = resistedTurn(for: -value.translation.width / width)
      }
      .onEnded { value in
        let progress = -value.translation.width / width
        let projected = -value.predictedEndTranslation.width / width
        let isDecisive = abs(progress) > 0.3 || abs(projected) > 0.75

        if isDecisive, progress > 0, canTurnForward {
          complete(to: 1, offset: 1)
        } else if isDecisive, progress < 0, currentIndex > 0 {
          complete(to: -1, offset: -1)
        } else {
          withAnimation(.smooth(duration: 0.3)) {
            turn = 0
          }
        }
      }
  }

  private var canTurnForward: Bool {
    currentIndex < pageCount - 1
  }

  /// Keeps the first and last pages from turning past the spine.
  private func resistedTurn(for progress: CGFloat) -> CGFloat {
    let isBlocked = (progress > 0 && !canTurnForward) || (progress < 0 && currentIndex == 0)
    let limited = isBlocked ? progress * 0.12 : progress
    return min(max(limited, -1), 1)
  }

  private func complete(to end: CGFloat, offset: Int) {
    let destination = clamped(currentIndex + offset)

    guard !reduceMotion else {
      index = destination
      turn = 0
      return
    }

    withAnimation(.smooth(duration: 0.45), completionCriteria: .logicallyComplete) {
      turn = end
    } completion: {
      index = destination
      turn = 0
    }
  }
}

private struct PassportArtwork<Placeholder: View>: View {
  var name: String
  var zoom: CGFloat
  var placeholder: () -> Placeholder

  init(name: String, zoom: CGFloat = 1, @ViewBuilder placeholder: @escaping () -> Placeholder) {
    self.name = name
    self.zoom = zoom
    self.placeholder = placeholder
  }

  var body: some View {
    GeometryReader { geometry in
      if let image = UIImage(named: name) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .scaleEffect(zoom)
          .clipped()
      } else {
        placeholder()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

private struct USPassportCover: View {
  var fillsScreen = false

  var body: some View {
    GeometryReader { geometry in
      let designScale = min(geometry.size.width / 300, geometry.size.height / 430)

      ZStack {
        RoundedRectangle(cornerRadius: fillsScreen ? 0 : 24, style: .continuous)
          .fill(
            LinearGradient(
              colors: [PassportPalette.coverBlue, PassportPalette.coverNavy],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        RoundedRectangle(cornerRadius: fillsScreen ? 0 : 19, style: .continuous)
          .stroke(PassportPalette.gold.opacity(0.76), lineWidth: 1)
          .padding(fillsScreen ? 18 : 9)

        VStack(spacing: 12) {
          HStack {
            Spacer()
            Text("SAMPLE")
              .font(.caption2.weight(.bold))
              .tracking(1.8)
              .foregroundStyle(PassportPalette.gold)
          }

          Spacer(minLength: 10)

          VStack(spacing: 15) {
            Text("UNITED STATES OF AMERICA")
              .font(.system(size: 12, weight: .medium, design: .serif))
              .tracking(1.4)
              .multilineTextAlignment(.center)
              .foregroundStyle(PassportPalette.gold)

            PassportSeal()
              .frame(width: 112, height: 112)

            Text("PASSPORT")
              .font(.system(size: 27, weight: .medium, design: .serif))
              .tracking(4)
              .foregroundStyle(PassportPalette.gold)
          }

          Spacer(minLength: 10)

        PassportChipMark()
          .frame(width: 32, height: 22)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(30)
      .frame(width: 300, height: 430)
      .scaleEffect(designScale)
      .frame(width: 300 * designScale, height: 430 * designScale)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(alignment: .leading) {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
          .fill(.black.opacity(0.2))
          .frame(width: 4)
          .padding(.vertical, 24)
          .padding(.leading, 18)
      }
      .clipShape(RoundedRectangle(cornerRadius: fillsScreen ? 0 : 24, style: .continuous))
      .shadow(
        color: fillsScreen ? .clear : PassportPalette.coverNavy.opacity(0.26),
        radius: fillsScreen ? 0 : 22,
        x: 0,
        y: fillsScreen ? 0 : 14
      )
    }
    .accessibilityHidden(true)
  }
}

private struct PassportSeal: View {
  var body: some View {
    ZStack {
      Circle()
        .stroke(PassportPalette.gold, lineWidth: 1.2)

      Circle()
        .stroke(PassportPalette.gold.opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        .padding(7)

      VStack(spacing: 6) {
        PassportFlag()
          .frame(width: 48, height: 30)

        Text("USA")
          .font(.system(size: 10, weight: .semibold, design: .serif))
          .tracking(2)
          .foregroundStyle(PassportPalette.gold)
      }
    }
  }
}

private struct PassportFlag: View {
  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: 2) {
        ForEach(0..<7, id: \.self) { stripe in
          Rectangle()
            .fill(stripe.isMultiple(of: 2) ? PassportPalette.gold : .white.opacity(0.7))
        }
      }

      Rectangle()
        .fill(PassportPalette.coverNavy)
        .frame(width: 19, height: 16)
        .overlay {
          HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
              Circle()
                .fill(PassportPalette.gold)
                .frame(width: 2.5, height: 2.5)
            }
          }
        }
    }
    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
  }
}

private struct PassportChipMark: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 5, style: .continuous)
      .stroke(PassportPalette.gold, lineWidth: 1.4)
      .overlay {
        HStack(spacing: 0) {
          Rectangle()
            .fill(PassportPalette.gold)
            .frame(width: 1)
          Spacer(minLength: 0)
          Rectangle()
            .fill(PassportPalette.gold)
            .frame(width: 1)
        }
        .padding(.horizontal, 8)
        .overlay {
          Capsule()
            .stroke(PassportPalette.gold, lineWidth: 1)
            .frame(width: 11, height: 5)
        }
      }
  }
}

private struct PassportInteriorSpread: View {
  var fillsScreen = false

  var body: some View {
    HStack(spacing: 0) {
      PassportInteriorPage(isIdentityPage: true)

      Rectangle()
        .fill(
          LinearGradient(
            colors: [PassportPalette.paperShadow, PassportPalette.paper, PassportPalette.paperShadow],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 12)

      PassportInteriorPage(isIdentityPage: false)
    }
    .padding(fillsScreen ? 0 : 8)
    .background {
      if fillsScreen {
        PassportPalette.paper
      } else {
        RoundedRectangle(cornerRadius: 21, style: .continuous)
          .fill(PassportPalette.coverNavy)
      }
    }
    .overlay {
      if !fillsScreen {
        RoundedRectangle(cornerRadius: 21, style: .continuous)
          .stroke(PassportPalette.gold.opacity(0.8), lineWidth: 1)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: fillsScreen ? 0 : 21, style: .continuous))
    .shadow(
      color: fillsScreen ? .clear : PassportPalette.coverNavy.opacity(0.2),
      radius: fillsScreen ? 0 : 20,
      x: 0,
      y: fillsScreen ? 0 : 12
    )
    .accessibilityHidden(true)
  }
}

private struct PassportInteriorPage: View {
  var isIdentityPage: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text("UNITED STATES")
          .font(.system(size: 8, weight: .semibold, design: .serif))
          .tracking(0.8)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        Spacer(minLength: 2)

        Text(isIdentityPage ? "SAMPLE" : "VISAS")
          .font(.system(size: 7, weight: .bold))
          .tracking(0.6)
          .lineLimit(1)
      }
      .foregroundStyle(PassportPalette.pageInk)

      Rectangle()
        .fill(PassportPalette.pageInk.opacity(0.24))
        .frame(height: 0.8)

      if isIdentityPage {
        PassportIdentityIllustration()
      } else {
        PassportLibertyIllustration()
      }

      Spacer(minLength: 2)

      Text("SAMPLE · NOT VALID FOR TRAVEL")
        .font(.system(size: 7, weight: .semibold))
        .tracking(0.3)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .foregroundStyle(PassportPalette.demoRed)
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background {
      ZStack {
        LinearGradient(
          colors: [PassportPalette.paper, PassportPalette.paperTint],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        PassportSecurityLines()
          .stroke(PassportPalette.securityBlue.opacity(0.12), lineWidth: 0.8)
          .padding(4)

        Circle()
          .fill(PassportPalette.securityBlue.opacity(0.06))
          .frame(width: 100, height: 100)
          .offset(x: 38, y: 20)
      }
    }
    .clipped()
  }
}

private struct PassportIdentityIllustration: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .top, spacing: 7) {
        PassportPortrait()
          .frame(width: 58, height: 76)

        VStack(alignment: .leading, spacing: 5) {
          Text("PASSPORT")
            .font(.system(size: 8, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(PassportPalette.pageInk)

          Text("SAMPLE\nTRAVELER")
            .font(.system(size: 9, weight: .medium, design: .serif))
            .lineSpacing(2)
            .foregroundStyle(PassportPalette.pageInk)

          Spacer(minLength: 0)

          Text("SPECIMEN")
            .font(.system(size: 7, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(PassportPalette.demoRed)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
      }

      Text("UNITED STATES OF AMERICA")
        .font(.system(size: 7, weight: .semibold, design: .serif))
        .tracking(0.45)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(PassportPalette.pageInk.opacity(0.82))

      HStack(spacing: 4) {
        ForEach(0..<5, id: \.self) { _ in
          Circle()
            .fill(PassportPalette.securityBlue.opacity(0.25))
            .frame(width: 3, height: 3)
        }
      }
    }
  }
}

private struct PassportPortrait: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.78, green: 0.85, blue: 0.88), Color(red: 0.92, green: 0.85, blue: 0.72)],
        startPoint: .top,
        endPoint: .bottom
      )

      Circle()
        .fill(Color(red: 0.53, green: 0.35, blue: 0.27))
        .frame(width: 24, height: 24)
        .offset(y: -17)

      RoundedRectangle(cornerRadius: 19, style: .continuous)
        .fill(Color(red: 0.2, green: 0.29, blue: 0.38))
        .frame(width: 47, height: 45)
        .offset(y: 36)

      Text("SAMPLE")
        .font(.system(size: 6, weight: .bold))
        .tracking(0.5)
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(PassportPalette.demoRed.opacity(0.85), in: Capsule())
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 4)
    }
    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 5, style: .continuous)
        .stroke(PassportPalette.pageInk.opacity(0.25), lineWidth: 0.7)
    }
  }
}

private struct PassportLibertyIllustration: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text("A VIEW FROM LIBERTY ISLAND")
        .font(.system(size: 7, weight: .semibold))
        .tracking(0.5)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .foregroundStyle(PassportPalette.pageInk)

      ZStack(alignment: .bottom) {
        LinearGradient(
          colors: [Color(red: 0.47, green: 0.68, blue: 0.79), Color(red: 0.94, green: 0.79, blue: 0.58)],
          startPoint: .top,
          endPoint: .bottom
        )

        Circle()
          .fill(Color(red: 0.98, green: 0.88, blue: 0.65).opacity(0.9))
          .frame(width: 25, height: 25)
          .offset(x: 34, y: -34)

        HStack(alignment: .bottom, spacing: 4) {
          CityBuilding(width: 13, height: 28)
          CityBuilding(width: 17, height: 42)
          CityBuilding(width: 13, height: 32)
          Spacer(minLength: 0)
          StatueOfLibertyShape()
            .frame(width: 35, height: 63)
          CityBuilding(width: 16, height: 35)
        }
        .padding(.horizontal, 6)

        Rectangle()
          .fill(Color(red: 0.34, green: 0.57, blue: 0.61).opacity(0.88))
          .frame(height: 10)
      }
      .frame(height: 93)
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .stroke(PassportPalette.pageInk.opacity(0.18), lineWidth: 0.7)
      }

      HStack(spacing: 5) {
        PassportStamp(title: "NEW YORK")
        PassportStamp(title: "USA")
      }
    }
  }
}

private struct CityBuilding: View {
  var width: CGFloat
  var height: CGFloat

  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(PassportPalette.cityGreen.opacity(0.82))
        .frame(height: height - 5)
        .overlay {
          HStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { _ in
              VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                  Rectangle()
                    .fill(PassportPalette.paper.opacity(0.65))
                    .frame(width: 2, height: 3)
                }
              }
            }
          }
        }

      Rectangle()
        .fill(PassportPalette.cityGreen)
        .frame(height: 5)
    }
    .frame(width: width, height: height)
  }
}

private struct StatueOfLibertyShape: View {
  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        Capsule()
          .fill(PassportPalette.statueGreen)
          .frame(width: 13, height: 19)
          .overlay(alignment: .top) {
            Circle()
              .fill(PassportPalette.statueGreen)
              .frame(width: 12, height: 12)
              .offset(y: -8)
          }

        Trapezoid()
          .fill(PassportPalette.statueGreen)
          .frame(width: 28, height: 32)

        Rectangle()
          .fill(PassportPalette.statueGreen)
          .frame(width: 32, height: 8)
      }

      Capsule()
        .fill(PassportPalette.statueGreen)
        .frame(width: 5, height: 28)
        .rotationEffect(.degrees(28))
        .offset(x: 14, y: -41)

      Circle()
        .fill(PassportPalette.gold)
        .frame(width: 9, height: 9)
        .offset(x: 20, y: -53)

      HStack(spacing: 3) {
        ForEach(0..<5, id: \.self) { _ in
          Capsule()
            .fill(PassportPalette.statueGreen)
            .frame(width: 2, height: 7)
        }
      }
      .offset(y: -55)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }
}

private struct Trapezoid: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.width * 0.26, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.width * 0.74, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

private struct PassportStamp: View {
  var title: String

  var body: some View {
    Text(title)
      .font(.system(size: 6, weight: .bold))
      .tracking(0.6)
      .foregroundStyle(PassportPalette.stampBlue)
      .padding(.horizontal, 5)
      .padding(.vertical, 3)
      .overlay {
        Capsule()
          .stroke(PassportPalette.stampBlue.opacity(0.55), lineWidth: 0.8)
      }
  }
}

private struct PassportSecurityLines: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    for line in 0..<9 {
      let y = CGFloat(line) * 19 - 18
      path.move(to: CGPoint(x: 0, y: y))
      path.addCurve(
        to: CGPoint(x: rect.width, y: y + 35),
        control1: CGPoint(x: rect.width * 0.34, y: y - 32),
        control2: CGPoint(x: rect.width * 0.66, y: y + 68)
      )
    }

    return path
  }
}

private enum PassportPalette {
  static let coverBlue = Color(red: 0.075, green: 0.16, blue: 0.37)
  static let coverNavy = Color(red: 0.035, green: 0.09, blue: 0.23)
  static let gold = Color(red: 0.83, green: 0.70, blue: 0.42)
  static let paper = Color(red: 0.98, green: 0.96, blue: 0.88)
  static let paperTint = Color(red: 0.92, green: 0.94, blue: 0.90)
  static let paperShadow = Color(red: 0.73, green: 0.74, blue: 0.70)
  static let pageInk = Color(red: 0.16, green: 0.27, blue: 0.39)
  static let securityBlue = Color(red: 0.30, green: 0.54, blue: 0.65)
  static let demoRed = Color(red: 0.70, green: 0.23, blue: 0.22)
  static let cityGreen = Color(red: 0.24, green: 0.48, blue: 0.47)
  static let statueGreen = Color(red: 0.22, green: 0.45, blue: 0.42)
  static let stampBlue = Color(red: 0.25, green: 0.43, blue: 0.61)
}
