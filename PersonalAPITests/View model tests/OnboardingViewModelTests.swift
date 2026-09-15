import XCTest

@testable import PersonalAPI

@MainActor final class OnboardingViewModelTests: XCTestCase {
  func testCompletingOnboardingPersistsAcrossManagerReconstruction() {
    let graph = TestAppModelFactory()
    let vm = OnboardingViewModel(settings: graph.app.settingsFeature)
    vm.startDataset()
    let reloaded = SettingsManager(
      preferences: graph.preferences, repository: graph.repository,
      moments: graph.app.momentsFeature, profile: graph.app.profileFeature)
    reloaded.loadPreference()
    XCTAssertTrue(reloaded.onboarded)
  }
}
