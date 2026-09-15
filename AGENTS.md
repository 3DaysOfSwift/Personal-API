# Personal API architecture

Use Matthew’s AppModel architecture. Read Documentation/APPMODEL_IOS_APPLICATION_TEMPLATE.md completely before architecture changes; ARCHITECTURE.md maps it onto this project.

Canonical reference confirmed by Matthew: /Users/matthewthomas/Documents/Codex/2026-09-03/i-x20/outputs/Trend

Read that repository’s Skills/swift-concurrency-migration/SKILL.md for architecture work. Its Skills/xcode-project-dashboard/SKILL.md and bundled swift-architecture-analyser-tool provide the read-only evaluation workflow when a dashboard is requested. Do not infer scores from folder names or a successful build.

Preserve numbered Xcode groups, one adjacent ViewModel per screen, narrow feature APIs, AppModel.live() composition, repository-owned SwiftData and injectable dependencies. No business rules or persistence in Views/ViewModels. Preserve canonical original text and the PRODUCT.md principles.

Keep the local template snapshot aligned with intentional updates to the confirmed Trend reference. App bundle identifier remains com.3DaysOfSwiftConcurrency.PersonalAPI.

Validate with the iPhone Xcode test target when Simulator access is available. Package.swift runs the same shared Model/ViewModel tests on macOS without iPhone Views; always distinguish that evidence from iPhone runtime validation.
