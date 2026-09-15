# Personal API — Matthew’s AppModel architecture

This project follows the canonical template in the Trend repository Matthew confirmed:
`/Users/matthewthomas/Documents/Codex/2026-09-03/i-x20/outputs/Trend`.

A snapshot of its [AppModel iOS Application Template](Documentation/APPMODEL_IOS_APPLICATION_TEMPLATE.md) is included. [AGENTS.md](AGENTS.md) records the reference for future changes. The template is the authority; Trend is the implementation example.

## Visible structure

```text
PersonalAPI
├── 1 - View
│   ├── PersonalAPIApp.swift
│   ├── Theme
│   │   ├── AppColourTheme.swift
│   │   └── ThemeManager.swift
│   └── Views
│       ├── Root
│       ├── Onboarding
│       ├── Lock
│       ├── Training
│       ├── Moment Detail
│       ├── Profile
│       ├── Query
│       └── Settings
│           (each screen has its adjacent ViewModel)
├── 2 - AppModel
│   ├── AppModel.swift
│   ├── Features
│   │   ├── Moments
│   │   ├── Profile
│   │   ├── Query
│   │   ├── Authentication
│   │   └── Settings
│   └── User Data Storage
│       ├── Protocols
│       └── Local
├── 3 - App Resources
│   └── PrivacyInfo.xcprivacy
└── 4 - Swift Extensions
    (reserved; no extensions needed yet)

PersonalAPITests
├── View model tests
└── AppModel tests
    └── Test Support
```

Xcode groups mirror the physical folders. There are no empty CloudKit/Networking implementations, redundant routers or speculative managers. The first prototype uses no external package dependencies.

## Responsibilities

**Views** construct their own `@State private var viewModel`, own presentation, render state and report intent. Only immutable data reaches a destination. ThemeManager is a presentation dependency, supplied through the environment. Midnight is the production palette; Graphite is a Debug-only alternative. Both remain dark.

**ViewModels** retain narrow replaceable feature protocols, with live defaults from AppModel.shared. They own drafts, display errors, search lifetime and export presentation. They do not use SwiftData or repositories, mutate shared collections, or validate domain data.

**AppModel** has a fully explicit initializer and a `live()` factory. It assembles and retains the five feature managers. ApplicationDelegate initiates launch. A retained launch task starts Moments and Profile loads as structured children; repeated launch calls share that work. The test host skips the production graph. Authentication/onboarding preferences load before presentation.

**Feature managers** own validation, shared state, retrieval policy, authentication state and workflow ordering. Settings coordinates export and regeneration. Each capability is usable from another UI without moving business logic. Managers publish successful writes only after the repository returns.

**Repositories** own database, JSON and device integration. LocalDataStore is an actor, lazily opens a SwiftData container and creates fresh contexts with autosave disabled. Models and UI receive immutable Sendable snapshots. LocalDeviceAuthentication wraps LocalAuthentication; LocalPreferences wraps app-owned UserDefaults.

## Capture and enrichment

TrainingView → TrainingViewModel → MomentsFeature → MomentsManager → PersonalDataRepository → LocalDataStore.

The manager rejects blank input without trimming the stored text, assigns a stable ID and capture time using its injected clock, saves the source, publishes it, and requests enrichment. The command returns after the raw save, so the draft can clear independently of analysis. A save failure retains the draft and publishes no new source.

MomentProcessor accepts immutable source input. LocalMomentProcessor is an actor that currently extracts a title only. The app-owned enrichment task coalesces requests and attempts each pending source once per pass; failed processing remains pending and exposes a retry message. Regeneration finishes an existing pass, marks all analyses pending in one repository transaction and requests another pass. Original text is never replaced.

A FIFO continuation gate in MomentsManager orders repository writes/reads with publication across suspension. ProfileManager uses the same local pattern for its independent collection. They do not serialize unrelated feature workflows. Cancellation is checked before writes begin; once saved, the committed result is published even if cancellation arrives during the write. Enrichment intentionally outlives its initiating screen.

## Retrieval and search lifetime

QueryManager reads authoritative original Moments through the repository. Its injected
OnDeviceMomentSearch actor uses Foundation Models on iOS 26+/macOS 26+ when the local
Apple Intelligence model is available. Each fresh model session selects relevant
passage indices from JSON input; only validated repository IDs become evidence.
Entries are split into overlapping 1,200-character passages in batches of three,
so long entries are not silently truncated. Results are deduplicated and ordered
by capture date, capped at 20 original Moments. This is a small-dataset semantic
search prototype, not an embedding index or a generated-answer system.

The model treats question/entry text as untrusted data. Prompt instructions alone
cannot prove relevance; source inspection remains essential. Invalid IDs, unavailable
models and generation failures fall back to keyword overlap with explicit status.
Cancellation propagates instead of starting fallback. A valid empty AI selection
remains empty. Every search uses a fresh repository snapshot and writes nothing.

QueryViewModel owns the replaceable task and request identity, preventing late
results from replacing a newer search. The UI reports AI versus keyword search and
lets users open exact source text. Questions are limited to 500 characters. Profile
facts, relative-date resolution, cross-entry reasoning and generated answers are
outside this first search slice. Runtime model availability is checked each search.

## Authentication

Enabling/disabling the lock requires device-owner authentication. Backgrounding locks the feature, invalidates any active system context, and increments an operation generation. A late successful authentication cannot unlock after that transition. Authentication-caused inactive transitions only conceal the screen, avoiding a lock loop.

The app gate is not a separate encryption system. Exported JSON is plaintext. Physical-device Face ID/passcode and app-switcher checks remain required. [Apple’s LocalAuthentication documentation](https://developer.apple.com/documentation/localauthentication/logging-a-user-into-your-app-with-face-id-or-touch-id) describes the underlying system policy.

## Persistence and compatibility

The original v1 SwiftData class identities (`Moment`, `PersonalFact`) and stored properties are retained inside storage. Domain snapshots are separate types, so refactoring folder ownership does not require renaming the persistent entities. No store-reset fallback is used. Failed loads remain visible and retryable; one feature’s error does not conceal the others.

The default configuration still disables CloudKit. Before any future persisted-schema change, introduce a tested VersionedSchema/SchemaMigrationPlan using real v1 fixtures. This refactor has not been tested against an installed iPhone’s pre-refactor store.

Queries, export and enrichment still load whole collections. Indexed lookup, pagination and background batching are subsequent scaling work, not claims about this prototype.

## Open export

The v1 JSON structure is retained: format, schemaVersion, exportedAt, moments and facts. Source text, UUIDs, source provenance, timestamps and derived envelopes survive export. Dates use Foundation Codable numeric seconds since 2001-01-01 UTC. Unknown/corrupt derived data remains preserved as base64 while raw text stays readable; the UI exposes a metadata issue and regeneration option.

Export reads both collections without suspension between them on the repository actor, preventing app writes from interleaving. SwiftUI’s FileDocument adapter stays in the View layer. Import is not yet implemented.

PrivacyInfo declares app-owned UserDefaults access using CA92.1, consistent with [Apple’s required-reason documentation](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype). No developer-server collection or tracking is implemented.

## Foundation Models extension

Implement a new availability-gated MomentProcessor adapter. Keep extractive fallback for unsupported or unavailable models. Require source support for factual tags, distinguish explicit emotions from interpretations, and preserve uncertainty in significance/life-event annotations. Dates need evidence, precision and time-zone context; inferred dates must not replace user-supplied dates. Add those evidence fields before inferring classifications.

Treat journal content as data, never instructions. Test negation, quotations, imagined events and events involving other people. Keep retrieval evaluation separate from synthesis evaluation; future answers must cite original source IDs.

## Validation

[VALIDATION.md](VALIDATION.md) records executed checks and limits. The canonical [architecture checklist](Documentation/ARCHITECTURE_REVIEW.md) is an implementation review, not a scored project dashboard.
