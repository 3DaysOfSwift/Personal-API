// swift-tools-version: 5.9
import PackageDescription

// macOS test harness for the exact shared app sources; this is not a Mac app.
let package = Package(name: "PersonalAPIModelChecks", platforms: [.macOS(.v14)], targets: [
    .target(name: "PersonalAPI", path: "PersonalAPI", exclude: ["3 - App Resources", "4 - Swift Extensions", "1 - View/PersonalAPIApp.swift", "1 - View/Theme", "1 - View/Views/Lock/LockView.swift", "1 - View/Views/Moment Detail/MomentDetailView.swift", "1 - View/Views/Onboarding/OnboardingView.swift", "1 - View/Views/Profile/ProfileView.swift", "1 - View/Views/Query/QueryView.swift", "1 - View/Views/Root/RootView.swift", "1 - View/Views/Settings/SettingsView.swift", "1 - View/Views/Training/TrainingView.swift"], sources: ["2 - AppModel", "1 - View/Views/Lock/LockViewModel.swift", "1 - View/Views/Moment Detail/MomentDetailViewModel.swift", "1 - View/Views/Onboarding/OnboardingViewModel.swift", "1 - View/Views/Profile/ProfileViewModel.swift", "1 - View/Views/Query/QueryViewModel.swift", "1 - View/Views/Root/RootViewModel.swift", "1 - View/Views/Settings/SettingsViewModel.swift", "1 - View/Views/Training/TrainingViewModel.swift", "1 - View/Views/Settings/ExportDocument.swift"], swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
    .testTarget(name: "PersonalAPITests", dependencies: ["PersonalAPI"], path: "PersonalAPITests", swiftSettings: [.enableUpcomingFeature("StrictConcurrency")])
])
