import Observation

@MainActor @Observable final class OnboardingViewModel {
  private let settings: any SettingsFeature
  init(settings: any SettingsFeature = AppModel.shared.settingsFeature) { self.settings = settings }
  func startDataset() { settings.completeOnboarding() }
}
