# Personal API — first iPhone project

Open **PersonalAPI.xcodeproj**, choose the **PersonalAPI** scheme and an iPhone simulator, then Run. For a physical iPhone, select your development team under Signing & Capabilities. No packages, API keys or server setup are needed.

- Minimum iOS: 17.0
- Created and compiled with Xcode 26.2
- App bundle ID: `com.3DaysOfSwiftConcurrency.PersonalAPI`
- Test bundle ID: `com.3DaysOfSwiftConcurrency.PersonalAPI.PersonalAPITests`

Read [PRODUCT.md](PRODUCT.md) for scope and principles, and [ARCHITECTURE.md](ARCHITECTURE.md) for data flow and extension boundaries.

## Try the complete slice

1. Start your dataset and log “I had an idea for a garden app”.
2. Open the saved Moment and inspect its unchanged text and derived title.
3. Query “garden idea”; expand “Based on 1 Moments” and open its source.
4. Query “hospital” to check the no-evidence response.
5. Add a profile fact and export JSON in Settings; inspect the original words and fact.
6. Relaunch and verify persistence. Enable the privacy lock on a device with authentication configured; background and reopen the app.

## Tests

Use Product → Test. 22 tests cover the screen ViewModels, feature failures and concurrency, raw-source/export preservation, and SwiftData persistence. You can also run `swift test` on macOS to execute the same shared Model/ViewModel tests without Simulator. See VALIDATION.md for checks actually completed in this environment.

The first processor extracts titles only. Foundation Models, iCloud sync, import, HealthKit and semantic/generative queries are intentionally deferred.

## Architecture reference

This project now uses Matthew’s numbered AppModel structure from the confirmed Trend repository. Read [AGENTS.md](AGENTS.md), the [canonical template](Documentation/APPMODEL_IOS_APPLICATION_TEMPLATE.md), and the [architecture review](Documentation/ARCHITECTURE_REVIEW.md) before changing the design.
