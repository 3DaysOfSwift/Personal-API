import Foundation
import Observation

@MainActor @Observable final class AuthenticationManager: AuthenticationFeature {
  private(set) var enabled = false
  private(set) var unlocked = false
  private(set) var authenticating = false
  private(set) var error: String?
  private let client: any DeviceAuthentication
  private let preferences: any PreferencesRepository
  private var generation = 0
  init(client: any DeviceAuthentication, preferences: any PreferencesRepository) {
    self.client = client
    self.preferences = preferences
  }
  func loadPreference() { enabled = preferences.lockEnabled }
  func lockForBackground() {
    generation += 1
    client.cancel()
    unlocked = false
  }
  private func authenticate() async -> Bool {
    guard !authenticating else { return false }
    authenticating = true
    let request = generation
    defer { authenticating = false }
    do {
      let success = try await client.authenticate()
      try Task.checkCancellation()
      guard generation == request else { return false }
      unlocked = success
      error = success ? nil : "Authentication was not completed."
      return success
    } catch is CancellationError {
      return false
    } catch {
      guard generation == request else { return false }
      self.error = error.localizedDescription
      return false
    }
  }
  func unlock() async { _ = await authenticate() }
  func setEnabled(_ value: Bool) async {
    guard await authenticate() else { return }
    preferences.lockEnabled = value
    enabled = value
  }
}
