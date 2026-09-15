import Observation
@MainActor @Observable final class LockViewModel {
    private let authentication: any AuthenticationFeature
    init(authentication: any AuthenticationFeature = AppModel.shared.authenticationFeature) { self.authentication = authentication }
    var error: String? { authentication.error }
    var authenticating: Bool { authentication.authenticating }
    func unlock() async { await authentication.unlock() }
}
