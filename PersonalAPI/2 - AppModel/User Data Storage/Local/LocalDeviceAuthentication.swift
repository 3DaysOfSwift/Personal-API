import Foundation
import LocalAuthentication

@MainActor final class LocalDeviceAuthentication: DeviceAuthentication {
  private var context: LAContext?
  func authenticate() async throws -> Bool {
    let context = LAContext()
    self.context = context
    defer { self.context = nil }
    return try await context.evaluatePolicy(
      .deviceOwnerAuthentication, localizedReason: "Unlock your Personal API")
  }
  func cancel() { context?.invalidate() }
}
