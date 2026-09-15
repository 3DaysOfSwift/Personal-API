import Foundation

@MainActor protocol AuthenticationFeature: AnyObject, Sendable {
  var enabled: Bool { get }
  var unlocked: Bool { get }
  var authenticating: Bool { get }
  var error: String? { get }
  func loadPreference()
  func lockForBackground()
  func unlock() async
  func setEnabled(_ value: Bool) async
}
@MainActor protocol DeviceAuthentication: AnyObject, Sendable {
  func authenticate() async throws -> Bool
  func cancel()
}

extension AuthenticationFeature {
  var requiresUnlock: Bool { enabled && !unlocked }
}
