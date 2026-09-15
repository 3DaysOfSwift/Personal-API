# Grounded answers — 15 September 2026

- 32 deterministic tests pass; one opt-in live-model test is skipped by default.
- iPhone app and test targets: TEST BUILD SUCCEEDED, Xcode 26.2.
- Added checks for supported-answer delivery, fabricated-quote rejection with retained
  evidence, abstention and ViewModel presentation of actual generated text.
- The user’s screenshot confirms semantic retrieval ran on their simulator. This
  does not establish answer-generation quality, which still needs a live simulator
  check outside this session’s inference-service restriction.
- No journal database, schema or bundle identifier changes. No simulator reinstall
  or erase was performed. Run the updated app from Xcode to test the answer stage.

## Previous search implementation evidence

# Local AI search — 15 September 2026

- 28 deterministic tests pass. The suite now also contains one opt-in real-model
  evaluation, skipped unless PERSONAL_API_LIVE_AI_TEST=1.
- iPhone Simulator app and test targets build with Xcode 26.2, arm64/x86_64.
  The command-line build uses OTHER_SWIFT_FLAGS=-disable-sandbox to allow compiler
  macro subprocesses in this environment; this is not a project setting.
- Coverage includes injected semantic selection without keyword overlap, unchanged
  source records, unavailable-model fallback, rejection of invented IDs, cancellation,
  AI abstention, full-text chunking and existing stale-result suppression.
- The actual Mac model reports available, but an attempted synthetic real-model
  query failed with Apple inference service “Sandbox restriction” (lookup error 159).
  This is recorded as an unverified live path, not a passing AI quality test.
- CoreSimulator service access is blocked from this session. The updated app was
  not installed or run against the user’s iPhone Air journal database. No simulator
  was erased, no app was uninstalled, and the persistence schema/bundle ID are unchanged.

Run the app from Xcode and confirm “On-device AI” after a search. Check paraphrases,
unrelated questions, long entries and repeated searches against known journal facts.
Open each source to assess false matches and omissions. Use the opt-in synthetic
model test outside the restricted environment for a repeatable initial quality check.

## Earlier prototype evidence

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
