import Foundation
import Observation
@MainActor @Observable final class RootViewModel {
    private let settings: any SettingsFeature
    private let authentication: any AuthenticationFeature
    init(settings: any SettingsFeature = AppModel.shared.settingsFeature,
         authentication: any AuthenticationFeature = AppModel.shared.authenticationFeature) {
        self.settings = settings; self.authentication = authentication
    }
    var requiresUnlock: Bool { authentication.enabled && !authentication.unlocked }
    var needsOnboarding: Bool { !settings.onboarded }
    func enteredBackground() { authentication.lockForBackground() }
}
