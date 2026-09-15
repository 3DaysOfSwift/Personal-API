import Foundation

@MainActor protocol ProfileFeature: AnyObject, Sendable {
  var facts: [PersonalFactSnapshot] { get }
  var loadError: String? { get }
  var isLoading: Bool { get }
  func canSave(label: String, value: String) -> Bool
  func loadIfRequired() async
  func refresh() async
  func addFact(label: String, value: String) async throws
}
