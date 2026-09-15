# Canonical architecture review

Scope: PersonalAPI app target and its test target, after the September 15 refactor. Reviewed against Trend’s canonical 20-question checklist. This is a source-based implementation review, not an Xcode Project Dashboard score or a claim that all runtime paths are tested.

| Template check | Result and evidence |
| --- | --- |
| 1. Folder ownership | Numbered filesystem folders and PBXGroups separate presentation, features, storage and resources. |
| 2. Dedicated ViewModels | Eight screen Views each have an adjacent, dedicated ViewModel. |
| 3. Screen ownership | Each uses `@State private var viewModel`; no ViewModel is cached by another model. |
| 4. Clean View inputs | Views require no feature, repository, AppModel or behavioural closure; Moment Detail accepts a plain immutable snapshot. |
| 5. Model rules | Managers own blank-input validation, retrieval semantics, authentication policy, persistence ordering and regeneration. |
| 6. Reusable capabilities | Another UI can use MomentsFeature, ProfileFeature, QueryFeature, SettingsFeature and AuthenticationFeature directly. |
| 7. Narrow dependencies | ViewModels accept only relevant feature protocols and expose live defaults; tests replace them. |
| 8. Composition root | AppModel.live assembles dependencies; AppModel.init is explicit. Launch coordinates independent feature loads only. |
| 9. Repository boundary | SwiftData appears only in storage implementation files; Views and ViewModels never import it. |
| 10. Awaitable work | Feature commands and ViewModel commands are awaitable. Views hold no Task handles. |
| 11. Concurrency preserved | Startup loads are structured concurrent children. Writes/publication serialize only per owning collection. |
| 12. Deterministic time | Moments, Profile and processor receive injected clocks; tests use a fixed time. |
| 13. ViewModel suites | Each of eight ViewModels has its own test file; 22 shared tests execute overall. |
| 14. Readable names | Named save/load/record/search/export/unlock commands trace directly to their feature. |
| 15. Earned abstractions | Feature protocols isolate UI; repository and authentication protocols replace external systems; processor permits future enrichment. |
| 16. Shared state | MomentsManager/ProfileManager own their collections. Authentication/Settings own their feature state. ViewModels keep drafts and query presentation only. |
| 17. Task lifetimes | Launch and enrichment handles are app-owned; search is ViewModel-owned and replaceable; button saves are durable event bridges. |
| 18. Executor ownership | SwiftData, JSON export, retrieval and title extraction run on actors; observable publication returns to MainActor. |
| 19. Honest failures | Failed saves retain drafts; failed loads expose retry; processing errors preserve raw text and remain visible; search errors are not abstentions. |
| 20. Domain ownership | MomentSnapshot/MomentAnalysis and PersonalFactSnapshot live with their features. SwiftData models and JSON transport records remain in storage. |

## Operation review

- **Capture:** validate → acquire feature gate → check cancellation → save → publish → schedule app-owned enrichment. A subsequent refresh uses the same gate and cannot publish an older read over that save. Two user-intent saves from one screen are guarded by its ViewModel; distinct valid manager commands each create a Moment.
- **Enrichment:** one retained task per manager; each pending ID attempted once in a pass. Processor failure and metadata-save failure leave raw data intact. New sources added during processing join the pending list. Explicit regeneration awaits the old pass first.
- **Profile:** validation belongs to ProfileManager. Save and refresh retain exclusive ownership through persistence/publication. A failure does not clear the draft.
- **Query:** original source → actor retrieval → ViewModel request-ID guard. Superseded/disappeared requests cannot publish. Search cancellation cannot undo or affect saved Moments.
- **Authentication:** duplicate evaluations are gated; background invalidates the system context and operation generation. A late result cannot unlock. The operating system remains an external boundary needing device testing.
- **Settings/export:** export is a read-only actor operation with a ViewModel presentation gate. Failed export clears stale document data. Regeneration uses the Moments feature’s workflow; Settings does not mutate stored models.
- **Launch:** ApplicationDelegate starts the shared production graph once. Two structured feature loads run independently. XCTest skips this live startup.

## Practical limits

The standard dashboard generator was located in Trend’s `Skills/xcode-project-dashboard/swift-architecture-analyser-tool`. A full scored dashboard was not requested or generated; no percentages or architecture ratings are inferred from this checklist.

The runtime evidence is macOS execution of the same Model and ViewModel files via Package.swift. It excludes iPhone Views and real authentication. iPhone test targets compile, but Simulator/device UI, File picker and actual Face ID lifecycle still need verification. Source review cannot establish global race freedom. Whole-dataset scans and large-dataset performance remain future work.
