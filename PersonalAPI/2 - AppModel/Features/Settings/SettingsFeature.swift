import Foundation

@MainActor protocol SettingsFeature: AnyObject, Sendable {
  var onboarded: Bool { get }
  var momentCount: Int { get }
  var factCount: Int { get }
  var enrichmentError: String? { get }
  func loadPreference()
  func completeOnboarding()
  func exportDataset() async throws -> Data
  func regenerateMetadata() async throws
}
