# Unsupported answer correction — 15 September 2026

The user reported an unrecorded claim of loneliness. That phrase matched a fictional
style example in the answer instructions. This is strong evidence of example leakage,
not evidence of learning from feedback. Removed the factual example; added explicit
question relevance and insufficient-evidence instructions. No journal data was changed.
Live validation must repeat the original question and check that the answer admits
missing evidence about parenting instead of supplying an invented emotion.
Feedback buttons remain session-only and do not train or update the local model.

# Reliability update — 15 September 2026

- The user supplied evidence of a model refusal followed by a successful generated
  answer after manual retry on the simulator. The full on-device path is demonstrated.
- Added greedy sampling, one bounded retry for temporary service failures and a
  duplicate-submission guard. No automatic retry of refusals or guardrail responses.
- 39 deterministic tests pass; one opt-in live-model test is skipped. New checks
  cover retry recovery, retry exhaustion, permanent errors, cancellation during
  backoff and refusal/guardrail classification. iPhone app and test targets build.
- Whether this reduces refusal frequency needs repeated simulator trials. Greedy
  sampling does not guarantee determinism of the entire service or safety checks.

## Previous evidence

# Conversational response correction — 15 September 2026

The user demonstrated answer failure on the simulator after successful retrieval.
The previous catch-all error did not distinguish quote-validation failure from a
Foundation Models error, so its exact cause cannot be inferred from that screenshot.

Removed mandatory generated quotations/structured answer decoding. Plain-text model
answers now occupy the main response area; sources are collapsed and failure reasons
are explicit. Added regression tests for answers without quotes and failure wording.
34 tests pass, one opt-in model test is skipped.
The iPhone app/test targets build. Live answer generation remains unverified in this
sandbox; the user must run the updated app to verify the response or see the actual
model failure category. No claim of successful live answering is made from mocks.

## Previous implementation evidence

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

## Conversation prototype — 15 September 2026

- Shared macOS suite: 45 passed, 1 opt-in live-model check skipped, no failures.
- iPhone Simulator build-for-testing: succeeded with the existing development-environment compiler flag.
- Added checks for bounded question context, fresh journal reads after logging, saved chat reload, feedback persistence, cancellation, failed writes, corrupt archive preservation, and independent chat deletion.
- No simulator UI or live Foundation Models inference was executed by this validation. Follow Documentation/CONVERSATION_TESTING.md in the user's existing simulator. Existing journal data was not erased or migrated.

## Local query index — 15 September 2026

Shared macOS checks: 56 passed, one live-model test skipped, no failures. Added boundary checks proving a job query does not send school-only passages to the semantic worker, childhood remains searchable, topic changes drop old context, follow-ups retain references, new/deleted entries refresh candidates, unmatched queries do not call AI, and candidate payloads are bounded exact source excerpts. Project-file syntax passes validation. Live inference and simulator UI remain unverified in this environment.

## Job-answer regression tests — 15 September 2026

57 deterministic checks passed, 3 opt-in live checks skipped. Direct live generation was attempted separately and failed at model-service connection with sandbox restriction error 159; no live answer-quality conclusion is supported. The PersonalAPI Live AI Checks scheme enables direct and end-to-end checks from Xcode. Details: Documentation/JOB-ANSWER-TEST-RESULTS.md.

## Automatic journal fact indexing — 2026-09-15

Shared macOS suite: 70 tests executed, 66 passed, 4 opt-in live model tests skipped,
0 failures. Includes real temporary SwiftData stores for replacement, reopen, export,
legacy preservation and rejected unsupported replacements. New feature tests cover
backfill, extraction failure/retry, qualifications, source-grounded search payloads,
and stale/orphaned source exclusion. Diff whitespace check passed.
This does not validate the installed iPhone store migration or the live AI model.
Device follow-up: launch with an existing journal, let indexing finish, query an
explicit recorded statement, and inspect its original journal source. No Facts input
screen should appear. No user data was erased and no commit was made.

## Launch build repair — 16 September 2026

Removed the failing LaunchScreen.storyboard and all project references. Both app configurations now merge an explicit Info.plist containing UILaunchScreen with LaunchBackground and LaunchBrand assets. The launch artwork preserves the existing fingerprint and grey wordmark. Project/plist syntax and git diff whitespace checks pass. A fresh simulator build contains no CompileStoryboard step; full build remains unverified because asset compilation cannot access any simulator runtimes in this execution environment. Device appearance remains unverified.

## Chat layout cycle repair — 16 September 2026

User confirmed the app runs after the launch repair, but supplied repeated AttributeGraph cycle warnings. Removed the composer geometry callback and the SwiftUI clearance/height state that rebuilt the hosted composer after layout. Transcript and composer now share a native controller with direct constraints to one another and the keyboard guide. Removed the obsolete passthrough overlay controller. Responder changes are deferred outside updateUIView and coalesced using the current focus request. Swift parsing, standalone iOS SDK typechecking of both native components, and diff checks pass. Runtime disappearance of the warnings and interactive keyboard tracking still require device validation; no simulator runtime is accessible here.
