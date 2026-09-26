# Passporte

A SwiftUI iPhone app scaffold set up for iPhone Duo with the iOS 27.1 SDK.

The starter workspace uses `NavigationSplitView` so its navigation adapts as the app moves between the compact outer display and the larger inner display. The Passports and Travel Documents sections are empty starting points for future features.

## Project layout

- `Project.json` defines the iOS app target and deployment settings.
- `App/PassporteApp.swift` is the app entry point.
- `App/ContentView.swift` contains the adaptive navigation shell.
- `App/OverviewView.swift` contains the starter overview screen.
- `App/Assets.xcassets` contains the app icon and accent color.

Open this repository in Bitrig to build and run the app with the iPhone Duo simulator.

## Contributing

Create a branch for your changes, keep commits focused, and include a description of the change and any validation performed when opening a pull request.

## OpenAI API key

The local `.env` file is ignored by Git. Put `OPENAI_API_KEY` there only for a server-side service. The iOS app does not load `.env`; never bundle the key in the app or put it in Swift code. Mobile app keys can be extracted, so the app should send photo and trip context to a backend that calls OpenAI.
