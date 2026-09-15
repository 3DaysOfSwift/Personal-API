# Validation — 15 September 2026, after AppModel refactor

## Executed successfully

- **22 XCTest tests passed, zero failures**, using Package.swift on macOS and the actual shared Model/ViewModel source files (no alternate implementations).
- The suites cover all eight ViewModels, feature ownership and failures, concurrent saves/refresh, stale search suppression, cancellation, late authentication results, raw-source preservation, JSON export and a SwiftData read through a second independently created container.
- **iPhone Simulator app and test targets: TEST BUILD SUCCEEDED**, Xcode 26.2, Debug, arm64 and x86_64. No Swift source warnings or errors in the final build.
- Numbered Xcode groups match the filesystem. Bundle IDs remain unchanged in Debug/Release. PrivacyInfo.xcprivacy is included in the application resources phase.

## Reproduce

Open PersonalAPI.xcodeproj and use Product → Test on an available iPhone Simulator.

For shared logic tests without Simulator, run `swift test` from this project directory on macOS 14+ with Xcode installed. Package.swift compiles the same feature, repository and ViewModel files used by the iPhone target; it excludes iPhone-only Views and application startup.

This constrained tool environment required local cache directories and command-line `-disable-sandbox` for Swift’s nested macro launcher. Those environment accommodations are not stored in Xcode build settings. SwiftPM reported inaccessible optional user-cache folders, and CoreData reported a system notification-registration warning; the persistence test and all assertions nevertheless completed successfully.

## Not verified

- Running the iPhone app or XCTest suite in Simulator: write access to its folders was not granted.
- Visual layout, VoiceOver, keyboard/Dynamic Type, system Files export, real Face ID/passcode and app-switcher concealment.
- Physical-device signing/install or App Store packaging.
- Opening a pre-refactor store from an installed iPhone. Model names and stored fields were preserved by source inspection, but this is not a tested migration guarantee.
- Foundation Models, iCloud, semantic retrieval and imports: still outside this slice.

The macOS tests establish behaviour for the shared code, not an end-to-end iPhone verification or coverage percentage.
