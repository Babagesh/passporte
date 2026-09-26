# Passporte

A SwiftUI iPhone app scaffold set up for iPhone Duo with the iOS 27.1 SDK.

The workspace keeps the passport experience full-screen on iPhone Duo. When closed, the sample passport cover fills the outer display; when open, the original two-page interior fills the inner display. Add up to six visa-style stamps to each swipeable spread from the Duo toolbar. Stamps support 14 destinations, travel dates, diary notes, and photos from the camera or photo library.

Stamp details and compressed photos are stored locally in the app's Application Support directory.

## Project layout

- `Project.json` defines the iOS app target and deployment settings.
- `App/PassporteApp.swift` is the app entry point.
- `App/ContentView.swift` contains the adaptive navigation shell.
- `App/OverviewView.swift` contains the starter overview screen.
- `App/PassportsView.swift` contains the cover-to-interior passport experience.
- `App/PassportVisaPageOverlay.swift` places six selectable stamps across each full-screen spread.
- `App/StampEditorView.swift` creates and edits countries, dates, photos, and diary notes.
- `App/StampBookStore.swift` persists stamp records and their photos locally.
- `App/Assets.xcassets` contains the app icon and accent color.

Open this repository in Bitrig to build and run the app with the iPhone Duo simulator.

## Contributing

Create a branch for your changes, keep commits focused, and include a description of the change and any validation performed when opening a pull request.
