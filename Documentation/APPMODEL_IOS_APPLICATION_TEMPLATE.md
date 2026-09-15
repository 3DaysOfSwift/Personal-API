# AppModel iOS Application Template

## Purpose of this Document

This document defines the AppModel, Feature Manager, MVVM layered architecture
used by Trend and intended for future 3 Days of Swift Concurrency reference
applications. It is a free template for iOS developers and AI coding agents
creating, changing, or reviewing maintainable production SwiftUI applications
that use cooperative Swift Concurrency.

## 17 Years Experience in iOS

The template distils 17 years of experience building, publishing, and
maintaining commercial iOS applications with teams using many different custom
architectures. Those years revealed a recurring problem: teams can mistake
complexity for intelligence, even though every unnecessary layer makes an
application harder to understand, change, and maintain.

## A Template for Developers and AI

This architecture is offered as a practical gift to the iOS community. Its
consistent Xcode project structure gives developers a shared visual map of the
application and gives AI models strong, representative input. New features can
be added within a small, clearly owned area while communication with the rest
of the application remains explicit and coordinated. The goal is to improve
future code generation without sacrificing the readability and maintainability
required by the people who will own the code afterwards.

## Bundle Identifiers for 3 Days of Swift Concurrency Projects

Every new Xcode project we generate uses
`com.3DaysOfSwiftConcurrency.<AppName>` as its app bundle identifier. Each test
target appends its own name: `com.3DaysOfSwiftConcurrency.<AppName>.<TestTargetName>`.
For example, Trend uses `com.3DaysOfSwiftConcurrency.Trend`, with
`com.3DaysOfSwiftConcurrency.Trend.TrendTests` for its unit-test target and
`com.3DaysOfSwiftConcurrency.Trend.TrendUITests` for its UI-test target. Use
bundle-identifier-safe names and apply the identifiers consistently across
build configurations. This is our project-generation convention; developers
outside 3 Days of Swift Concurrency should use their own organisation's prefix.
Do not rename an existing application's bundle identifier without an explicit
request.

## Governing Principles

Two principles govern every rule in this document:

1. **Reduce code complexity.** A developer should be able to find behaviour,
   understand ownership, and make a change without learning an oversized object
   graph or tracing unnecessary layers.
2. **Apply KISS relentlessly.** Build direct, named features that perform the
   work the application needs. Add no coordinator, wrapper, abstraction,
   protocol, or architectural ceremony unless it provides an immediate and
   clearly explainable benefit.

## Coordinated Application Flow

The coordination between SwiftUI, ViewModels, feature managers, repositories,
and lower-level device APIs separates the application's execution paths and
behavioural responsibilities into one understandable flow through a layered
system. Together, these parts exist to make a real-world commercial application
simpler.

## Maintenance over Complexity

When an architectural choice adds code without making ownership, behaviour,
testing, or maintenance clearer, reject it. If a feature manager is divided
across several additional managers or layers, question what the increased
complexity genuinely provides. Continue only when its benefits outweigh its
maintenance cost.

The code is not merely editable. In a commercial application, a team of four or
more engineers may change it every working day for 48 weeks of the year. The
primary objective is to build the desired service. The secondary objective is
to ensure that the team can maintain that service easily throughout its life.

## Layered Architecture

The governing dependency flow is:

```text
View
  ↓
ViewModel
  ↓
Feature API
  ↓
Feature Manager
  ↓
Repository
  ↓
External System
```

User intent moves down through the layers and state or results flow back up. A
View reports intent to its ViewModel, the ViewModel requests a capability from
the Feature API, the Feature Manager applies the application's rules, and the
Repository interacts with storage, a server, or a device API.

Keep this route short, but never bypass an established owner for convenience.
Doing so places knowledge in the wrong type: a View begins to understand
persistence, a ViewModel duplicates business rules, or a Repository decides
application behaviour. Do not add layers for their own sake; use the fewest
layers needed while keeping every responsibility clear, testable, and easy to
find.

## Make the Architecture Visible in the Folder Structure

Use this top-level reading order:

```text
Application
├── 1 - View
│   ├── App.swift
│   ├── Theme
│   │   ├── AppColourTheme.swift
│   │   └── ThemeManager.swift
│   ├── SwiftUI Extensions
│   │   └── HabitErrorAlert.swift
│   └── Views
│       └── Feature Screen
│           ├── FeatureScreenView.swift
│           └── FeatureScreenViewModel.swift
├── 2 - AppModel
│   ├── AppModel.swift
│   ├── Features
│   │   └── Feature Name
│   │       ├── FeatureAPI.swift
│   │       ├── FeatureManager.swift
│   │       └── Feature-owned domain types
│   └── User Data Storage
│       ├── Protocols
│       ├── Local
│       ├── CloudKit
│       └── Networking
├── 3 - App Resources
│   ├── Assets.xcassets
│   ├── PrivacyInfo.xcprivacy
│   └── Application.entitlements
├── 4 - Swift Extensions
│   └── Type+Capability.swift
└── ApplicationTests
    ├── View model tests
    └── AppModel tests
```

The Xcode navigator must communicate the design without requiring a developer
to inspect source files.

### Strict No File Dumping Policy

Do not create vague dumping-ground folders such as `Helpers`, `Utilities`,
`Services`, `Common`, or `Managers`. Every folder must describe the specific
responsibility of the files it owns. If a file has no obvious destination,
clarify its responsibility rather than hiding it inside a generic collection.

### Colour Theme

Every iOS application requires a visual theme, even though most applications
ship with only one. Define that theme explicitly in `AppColourTheme` and let
`ThemeManager` own the selected theme and supply it consistently across every
screen.

Create more than one colour theme during development, even when only one is
intended to go live. Supporting another theme is an almost free user feature,
but its greater architectural value is enforcement: every developer must use
the selected theme instead of choosing colours independently inside Views. The
team and its designers gain one reviewable palette file containing the intended
values for the whole application.

This prevents scattered literals and subtly different versions of what should
be the same colour. Keep `AppColourTheme` and `ThemeManager` inside `1 - View`
because they control presentation rather than application behaviour. A theme
may remain development-only; the discipline created by supporting it still
improves the production code.

### Swift Extensions

Keep SwiftUI-specific extensions in `1 - View/SwiftUI Extensions`. Place
reusable extensions of Swift or Foundation types in `4 - Swift Extensions`.
This makes it immediately clear whether an extension belongs to presentation
or can be used throughout the application. Name a general extension after the
type and capability it adds, such as `Date+StartOfWeek.swift`.

### Domain Type Ownership

Domain values live with the feature that defines their meaning. A `WeightEntry`
belongs to Weight Log even though a repository persists it. Storage-only
representations—Codable documents, CloudKit field mappings, database records,
and transport payloads—remain private to their storage implementation. Never
place a domain type under storage merely because it is persisted.

## Maintain an Absolute UI and Model Boundary

`1 - View` owns presentation. `2 - AppModel` owns application behaviour.

The UI may decide:

- layout, colour, typography, animation, focus, transitions, and accessibility;
- whether a sheet, alert, menu, or navigation destination is visible;
- which chart point is highlighted;
- how model-provided information is formatted for display;
- whether a control is visually enabled using a decision already exposed by
  its ViewModel.

The UI must not decide:

- whether domain data is valid;
- what a domain-positive, domain-negative, complete, failed, or stale result
  semantically means;
- how values are calculated, classified, filtered, projected, or persisted;
- whether a date qualifies for a streak;
- which content should be selected or cycled;
- whether a purchase grants an entitlement;
- when data should be refreshed as part of an application workflow;
- how two or more feature operations form one business transaction.

Use this extraction test:

> Imagine adding an Apple Watch target to the Xcode project. Could the team
> create a working prototype in less than an hour without changing AppModel or
> any of its features? Every capability and its tested business logic should
> already exist in the Model—the AppModel layer—and be ready for a new UI to
> use.
>
> If the Apple Watch prototype requires a business decision to be copied from
> an iPhone View or ViewModel, business logic has leaked into the UI. Extract
> that decision into the Model layer and place it in the Feature Manager that
> owns the feature.

There is zero tolerance for business logic in the UI layer. Do not excuse it
because the calculation is short, because SwiftUI makes it convenient, or
because only one screen currently uses it.

The Model determines the semantic result. The UI remains free to decide how
that result looks: a tick, cross, colour, animation, alert, or inline message.

## Give Every Unique Screen Its Own ViewModel

Every screen-level SwiftUI `View` has one dedicated, tightly coupled ViewModel.
Store both files beside one another in that screen's folder:

```text
Coffee
├── CoffeeTrackingView.swift
└── CoffeeTrackingViewModel.swift
```

Never share one ViewModel class between different screen Views. Similar screens
still have different presentation behaviour, lifetimes, state, and future
requirements. Reuse belongs below the ViewModel boundary in a feature manager,
or in a stateless presentational View.

A small reusable View that only renders plain display data may remain stateless
and need no ViewModel. Examples include a chart receiving chart data, a streak
banner receiving a snapshot, or a reusable card receiving strings and colours.
It must not acquire feature access or business behaviour.

### Keep SwiftUI View Construction Fast

✅ **Correct — the View owns its bespoke ViewModel and requires no dependency
injection:**

```swift
struct CoffeeTrackingView: View {
    @State private var viewModel = CoffeeTrackingViewModel()

    var body: some View {
        Text(viewModel.screenTitle)
    }
}

CoffeeTrackingView()
```

❌ **Incorrect — the caller constructs and injects the ViewModel:**

```swift
struct CoffeeTrackingView: View {
    @State private var viewModel: CoffeeTrackingViewModel

    init(viewModel: CoffeeTrackingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text(viewModel.screenTitle)
    }
}

CoffeeTrackingView(viewModel: CoffeeTrackingViewModel())
```

A screen View is a lightweight description of what the interface should look
like for the current state of its ViewModel. SwiftUI may create and discard View
values frequently while evaluating changes. Constructing a View must therefore
remain fast and must not start loading, persistence, networking, observation,
or any other work as a side effect.

Every screen conventionally names its one direct backing object `viewModel` and
creates it at the property declaration.

The ViewModel initializer must also be quick and free of work-starting side
effects. It may retain the feature capabilities it needs from `AppModel.shared`,
but loading and other asynchronous work begin only through an explicit method.
`@State` associates the ViewModel with the screen's SwiftUI identity so the same
logical screen continues to observe its existing ViewModel across redraws.

Apart from plain input data, SwiftUI presentation state, environment-provided
presentation values, and this `viewModel`, do not make a screen View the owner
of long-lived reference objects. The View describes and reflects state; it does
not become an object-lifetime coordinator.

A ViewModel:

- is named after exactly one View;
- uses `@MainActor` and `@Observable` when it exposes UI-observed state;
- is created and owned by its View using `@State`;
- lives only as long as that View lives;
- is never cached by a root ViewModel, another ViewModel, or AppModel;
- never calls another ViewModel;
- retains the smallest coherent set of narrow feature APIs required by its
  screen rather than the complete AppModel;
- converts feature state into presentation-ready values;
- accepts user intent and calls its feature API;
- owns screen-specific error text, loading state, drafts, and presentation state;
- contains no reusable business rule.

The ViewModel initializer provides the live feature as its default while
remaining replaceable by tests:

```swift
init(habits: any HabitsFeature = AppModel.shared.habitsFeature) {
    self.habits = habits
}
```

This is deliberate dependency injection without forcing dependency plumbing
through every SwiftUI initializer.

Most screens need one feature API. A screen may legitimately need more—for
example, a habits screen may read both habits and purchase entitlement state.
Do not invent an artificial facade merely to meet a numerical rule. If the set
keeps growing, reconsider the screen responsibility or introduce one cohesive
feature workflow below the ViewModel boundary.

## Keep Screen Initializers Clean

A screen View must not receive:

- a ViewModel;
- AppModel;
- a feature manager;
- a repository;
- a closure taken from another ViewModel;
- navigation commands owned by an ancestor ViewModel.

Prefer:

```swift
TodayView()
```

Do not write:

```swift
TodayView(viewModel: rootViewModel.today)
TodayView(onAdd: rootViewModel.addEntry)
```

A destination may receive a plain, immutable domain value that identifies what
it displays or edits. A stateless presentational component may receive a display
struct, such as chart points. Inputs must be data—not access to the application
graph.

Each screen owns the sheet, alert, or navigation destination it presents. Do
not create an application-wide router merely to move local presentation state
away from the View.

## Use AppModel as the Composition Root and Feature Facade

`AppModel.shared` is the one production application graph. This is an explicit
architectural decision, not an accidental global variable.

AppModel:

- constructs and retains one instance of each app-scoped feature manager;
- exposes narrow feature APIs to ViewModels;
- guarantees that all scenes observe the same underlying application state;
- prevents SwiftUI environment placement from accidentally creating multiple
  Models or conflicting feature-manager instances;
- wires dependencies in one visible `live()` factory;
- requires every dependency in its initializer;
- permits isolated AppModel graphs to be assembled in tests;
- contains application-wide lifecycle coordination when that coordination does
  not belong to one feature;
- contains no SwiftUI, navigation state, screen identity, or feature-specific
  business rules.

AppModel contains application-scoped state only. Scene-specific navigation,
selection, drafts, focus, and presentation state remain owned by each scene's
Views and ViewModels. The singleton guarantees shared access to the application
graph; it does not create thread safety. Actor isolation and immutable values do
that.

Tests construct isolated application graphs and never mutate
`AppModel.shared`. Previews inject isolated feature implementations when they
need controlled state. Multiple production scenes use the shared graph so they
cannot accidentally disagree about persisted application state.

Do not give AppModel every function in the application. It is a facade over
coherent feature managers, not a god object. A command concerning one feature
belongs on that feature's API and manager.

Do not hide production dependency construction in default initializer values.
`AppModel.init` is fully explicit. `AppModel.live()` is the only place that
chooses live repositories, clients, clocks, and feature implementations.

## Organize Behaviour into Cohesive Feature Managers

A feature manager owns one coherent application capability. Name it directly:
`SettingsManager`, `PurchaseManager`, `HabitsManager`, not
`SettingsFeatureManager`.

A feature manager:

- exposes a narrow protocol written in domain language;
- owns business rules, validation, calculations, and classifications;
- coordinates repositories and lower-level collaborators for its workflow;
- publishes shared feature state after successful persistence;
- may be used by several different ViewModels without sharing those ViewModels;
- hides its internal collaborators from callers;
- has methods named after their real action or result.

A feature API protocol is an intentional boundary between ViewModels and the
Model. Do not automatically add protocols to internal helpers or value types.
Create a protocol when it defines a real capability boundary, enables a
required substitute, isolates an external system, or materially clarifies
ownership. Repository protocols normally earn this boundary because production
and test storage genuinely differ.

Prefer:

```swift
func recordCoffeeToday() async throws
func refreshStoreState() async
func makeWeightEntryDraft(editing entry: WeightEntry?) -> WeightEntryDraft
```

Avoid:

```swift
func start()
func begin()
func prepareForUse()
func process()
```

Names must let a junior developer understand what will happen without knowing
the implementation or navigating through several nested objects.

Do not expose deep object graphs such as
`appModel.progress.snapshot.chart.points`. Expose the capability or result the
caller actually needs through a clear feature API.

## Keep Persistence Behind Repository Contracts

Feature managers speak to repository protocols in domain language. They do not
know file paths, CloudKit record fields, HTTP routes, database tables, or cache
formats.

Repository implementations:

- isolate external systems;
- convert storage representations to and from domain values;
- protect mutable state using actors or another explicit isolation mechanism;
- define offline, retry, and synchronization behaviour;
- throw meaningful errors rather than silently inventing success.

Feature state becomes authoritative only after persistence succeeds unless the
feature explicitly defines optimistic behaviour and rollback.

Define what persistence success means. In a local-first application, a command
may succeed once data is durably stored on the device while remote
synchronization remains pending. Expose synchronization state separately; never
claim remote success when only the local write succeeded.

Never silently discard a business or persistence failure. Preserve user input
after a failed command and expose a recoverable error. `try?` is reserved for
explicitly best-effort work where failure has no business consequence, such as
an animation delay. Loading features expose meaningful idle, loading, ready,
empty, and failed states as appropriate. Retry behaviour must be intentional
and bounded.

## Make Concurrency Behaviour Honest and Visible

An `async` feature method is a testable unit of work. It is not itself a `Task`.
A `Task` represents the initiated lifetime of asynchronous work.

A SwiftUI event may create a `Task` to bridge a synchronous callback into an
async workflow:

```swift
Button("Save") {
    Task {
        await viewModel.save()
    }
}
```

It is completely acceptable for a View to create an unretained Task for a
direct user event. This is the simplest starting point. An unretained Task is
not trackable or explicitly cancellable, which may be exactly what a durable
command such as saving requires: the save can continue after the View
disappears.

The moment the application must track progress, prevent duplication, replace
older work, or cancel that Task, move Task ownership into the View's tightly
coupled ViewModel. Task tracking and cancellation are screen behaviour and must
not accumulate in the View. The ViewModel still exposes clear intent methods,
and the feature manager owns the underlying business workflow. Do not wrap every
async method in a ViewModel-owned Task merely to remove `Task` syntax from
SwiftUI.

A SwiftUI View must never store a `Task` handle in a stored property or in
`@State` so it can inspect or cancel that work later. Requiring a persistent
reference to the Task is the precise point at which the screen has gained
enough asynchronous behaviour for its custom ViewModel to own that lifetime.
The View continues to render the ViewModel's observable state and report user
intent; the ViewModel stores, replaces, or cancels the Task.

Store a Task when its lifetime must be managed. Examples include:

- cancelling an obsolete progress calculation when a new range is selected;
- retaining a long-lived StoreKit transaction observer;
- ensuring several scenes await the same launch workflow.

Choose the lifetime deliberately:

- durable commands such as persistence normally continue after presentation
  disappears;
- replaceable work such as searches, previews, and recalculations cancels when
  superseded;
- presentation-only work cancels when its screen disappears if continuing would
  have no value;
- long-lived observers are stored by the app-scoped owner and cancelled when
  that owner ends.

Cancellation is cooperative. Check cancellation before expensive work and
again before publishing its result. A cancelled older operation must never
overwrite newer state.

Prefer structured concurrency (`async let` or task groups) when child work
belongs to one parent operation. Use unstructured Tasks when the lifetime must
outlive the current call or be independently stored and managed.

Do not use `@unchecked Sendable` to silence a warning unless the type genuinely
maintains a documented thread-safety invariant. `Sendable` communicates safety;
it does not create safety. Prefer actor isolation, immutable value types, and
explicit task boundaries.

Do not change required concurrent behaviour into sequential behaviour simply to
make compiler diagnostics disappear or make code look easier. Code defines the
application's behaviour. Preserve independent startup and refresh operations as
independent work when the product requires them to begin together.

Main-actor isolation protects UI-observed state; it is not permission to perform
expensive work on the UI executor. File parsing, CPU-heavy calculations, image
processing, and blocking external work operate outside the Main Actor using
immutable `Sendable` inputs. Return to the Main Actor to publish the result.

Actors are reentrant across `await`. Revalidate assumptions after suspension.
When newer requests supersede older ones, use cancellation, operation identity,
or revision checks so stale work cannot publish over current state. Do not leave
observable state temporarily inconsistent across an `await` unless that
intermediate state is intentional and representable.

## Use Application Launch as an Opportunity to Load

Construction must not silently trigger asynchronous side effects. Initializers
assemble valid objects; clearly named methods perform work.

The first few seconds after launch are a valuable opportunity. The user is
looking at the first screen and deciding what to do, so AppModel can begin
loading app-scoped features before the user opens them:

```swift
func applicationDidFinishLaunching() async
```

`applicationDidFinishLaunching()` is an opportunity to trigger loading, not the
owner of the resulting feature state. It starts independent feature refreshes
concurrently so an API or storage request is likely to finish before the user
opens that screen. It does not interpret success, combine failures, show errors,
or decide whether the user may enter a feature.

Each feature manager owns its own load state and knows whether it is idle,
loading, loaded, empty, or failed. When a screen requests feature data, the
feature manager loads it if required or returns the state it already owns. A
failure is never hidden: the feature exposes a value that its ViewModel can
publish as soon as the screen appears.

Loading remains an explicit command such as `loadIfRequired()` or `refresh()`.
Reading a property must not secretly begin asynchronous work. The ViewModel asks
the feature to load when its screen appears; the feature decides from its current
state whether work is required. This keeps side effects visible without making
the ViewModel reproduce feature loading rules.

The screen is a window into that feature state. A failed screen explains the
problem and offers an appropriate retry command. Airplane Mode, a temporary API
failure, unavailable iCloud, and lost connectivity are legitimate user flows,
not exceptional states to conceal. Retrying asks the same feature manager to
load again; the View does not reproduce loading rules.

One feature failing must not prevent unrelated features from becoming usable.
If several scenes report application launch, they await the same stored Task
rather than starting duplicate opportunistic loads.

Individual feature managers have no concept of an application launch unless
launch is genuinely part of that feature's domain. `DailyTipManager.refresh()`
refreshes tips; it does not `beginLaunch()`.

Tests directly test that the launch opportunity triggers the intended features
without making AppModel responsible for their results. Each feature manager has
its own tests for successful loading, failed loading, retained failure state,
and retry.

Ordinary feature and ViewModel tests do not need to call application launch
unless the behaviour under test contractually depends on it.

## Keep Time and Other Volatile Dependencies Injectable

Business decisions involving the current date use an injected clock or date
function. Do not scatter `Date.now` through Views and ViewModels when the value
changes a business result.

Use a closure when production time must continue advancing:

```swift
let currentDate: @MainActor () -> Date = { .now }
```

Tests replace it with a fixed value. A stored `Date` is not a clock and becomes
stale. Views may use the current time solely for ephemeral visual presentation;
domain comparisons and date boundaries come from the feature layer.

Apply the same principle to randomness, identifiers, locale-sensitive business
rules, and external clients when deterministic tests require control.

Feature APIs should express date-relative business intent directly—such as
`todaysEntry`, `currentWeekSnapshot`, or `recordCoffeeToday`—instead of requiring
each ViewModel to obtain the date and reconstruct what “today” means.

## Use Observation Deliberately

For supported modern deployment targets, use `@Observable` rather than Combine
publisher plumbing for UI-readable reference state.

- Put `@Observable` on ViewModels and UI-observed feature managers.
- Put those types on `@MainActor` when their state is read by SwiftUI.
- Own a ViewModel with `@State` in its View.
- Create an `@Bindable` projection only when a SwiftUI control requires a
  writable binding.
- Do not manually forward change notifications.
- Do not add `@Published`, `ObservableObject`, or Combine without a concrete
  compatibility or publisher-composition requirement.

A computed property does not emit an independent notification. SwiftUI tracks
the observable stored properties read while evaluating it. Ensure the computed
property reads observable feature state or expose a stored observable result
when it represents completed asynchronous work.

## Preserve One Authoritative Owner for Shared State

Every piece of persisted or shared feature state has one authoritative owner:
its feature manager. ViewModels expose, format, and temporarily edit that state;
they do not maintain competing copies that require manual synchronization.

ViewModel-owned drafts, selections, focus, loading presentation, and transient
errors are permitted because they belong to one screen. Persisted collections,
entitlements, synchronization status, and domain results belong to their feature
manager.

Feature APIs expose state as read-only and provide named commands for mutation.
Views and ViewModels never mutate a feature collection directly. Every domain
mutation passes through the manager that owns its rules and persistence.

## Separate Domain Decisions from Display Decisions

Feature managers return semantic results and plain data snapshots. ViewModels
translate those results into the exact information their View needs. Views
render them.

For example:

```text
DailyTrendManager: classifies the weight direction
TodayViewModel: exposes the classification and formatted screen values
TodayView: chooses the icon size and transition for that classification
```

A ViewModel may choose display wording or expose a presentation flag. It must
not recreate the classification rule. If another interface would need the same
answer, move the answer into the feature manager.

Charts receive prepared chart data. SwiftUI draws the chart, but the Model owns
filtering, ranges, projection, interpolation inputs, trend calculations, and
domain bounds. Geometry and visual scales belong to the chart View only when
they do not alter domain meaning.

## Test the Same Boundaries the Architecture Advertises

The test navigator contains two primary groups:

```text
View model tests
AppModel tests
```

Rules for tests:

- every ViewModel has its own test file and suite;
- never create one shared test suite for several screen ViewModels;
- ViewModel tests inject an isolated feature capability;
- feature-manager tests exercise business rules and workflow coordination;
- repository tests exercise persistence, synchronization, and failure behaviour;
- AppModel tests verify construction and application-wide coordination;
- async functions are awaited directly in unit tests;
- task cancellation and race-prevention behaviour receive dedicated tests;
- clocks, repositories, and external clients use deterministic test doubles;
- tests describe observable behaviour, not private implementation details.
- tests that need AppModel assemble an isolated graph and never alter the shared
  production instance;
- concurrency tests cover cancellation, stale-result prevention, reentrancy,
  and partial failure where those behaviours affect correctness.

Do not use UI tests as compensation for async work hidden inside untestable
ViewModel-owned Tasks. Keep feature commands async and directly awaitable.

## Prefer Readable Domain Language over Architectural Ceremony

Architecture exists to make behaviour easier to find and change. Do not add a
factory, router, lifecycle manager, coordinator, service locator, use-case type,
or protocol merely because such a type is fashionable.

Add a layer only when it owns a stable and explainable responsibility. Remove a
layer when its name is more substantial than its contribution.

Comments explain ownership, non-obvious trade-offs, concurrency invariants, and
why a decision exists. They do not narrate obvious syntax.

Commercial Views keep display strings localisation-ready, support Dynamic Type,
provide meaningful accessibility labels, and respect Reduce Motion. Domain
values are never stored as already-localised display strings.

The goal is that a junior developer can follow one clear sentence:

```text
The View reports an intention to its ViewModel; the ViewModel asks one Feature;
the Feature applies the business rules and uses a Repository when data persists.
```

## Prohibited Patterns

Reject or refactor the following during review:

- business calculations, classifications, validation, or filtering in a View;
- reusable business rules in a ViewModel;
- one ViewModel shared by multiple unique screens;
- ViewModels stored by AppModel, a root ViewModel, or another ViewModel;
- Views receiving ViewModels, feature managers, AppModel, or service closures;
- ViewModels depending on the whole AppModel instead of the smallest coherent
  set of narrow feature APIs;
- feature managers containing navigation, sheets, dialogs, or screen names;
- repositories imported directly by Views or ViewModels;
- deep chains through the AppModel object graph;
- default live dependencies hidden in `AppModel.init`;
- asynchronous side effects inside initializers;
- Task handles stored by a SwiftUI View;
- vague lifecycle or action names such as `start`, `begin`, `process`, and
  `prepareForUse`;
- speculative folders, layers, or abstractions;
- `@unchecked Sendable` used as a compiler-warning escape hatch;
- serializing independent work when the required behaviour is concurrent;
- unstructured Tasks whose lifetime or cancellation affects correctness but is
  not stored and managed;
- Combine observation added where the Observation framework is sufficient.
- competing copies of shared feature state in multiple ViewModels;
- feature APIs exposing directly mutable domain collections;
- domain types placed under storage merely because they are persisted;
- swallowed business or persistence failures;
- expensive or blocking work performed on the Main Actor.

## Review Checklist

Before accepting a change, answer every question:

1. Can the folder location alone explain which layer owns every new type?
2. Does every unique screen have its own adjacent ViewModel?
3. Is each ViewModel named `viewModel`, owned with `@State`, and released with
   its View?
4. Can every View be created without receiving a ViewModel, AppModel, feature,
   repository, or behavioural closure?
5. Does every business decision live in a feature manager or lower Model layer?
6. Would an Apple Watch app be able to reuse the decision without copying UI
   code?
7. Does each ViewModel depend on the smallest coherent set of narrow,
   replaceable feature APIs?
8. Does AppModel only assemble and expose features or coordinate a genuinely
   application-wide workflow?
9. Are persistence and external-system details behind repository contracts?
10. Are async operations directly testable, with no Task handle stored by a
    View and every meaningful Task lifetime stored by its ViewModel or other
    correct owner?
11. Has required concurrency behaviour been preserved rather than simplified
    away?
12. Are time-dependent business rules deterministic in tests?
13. Does every ViewModel have its own focused test suite?
14. Can a junior developer read the names as plain English without learning the
    entire object graph first?
15. Was every new abstraction earned by a concrete responsibility?
16. Does each piece of shared state have one authoritative owner and mutate only
    through named feature commands?
17. Can every meaningful Task lifetime—durable, replaceable, presentational, or
    long-lived—be explained and managed appropriately?
18. Is expensive work kept away from the Main Actor while observable results
    return to it safely?
19. Are failures, partial loading, offline persistence, and retry behaviour
    represented honestly?
20. Are domain types stored with the feature that owns their meaning?

Every applicable answer must be yes. Marking a question not applicable requires
a short explanation. Otherwise, the change is not architecturally complete.
