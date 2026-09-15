import Foundation
import Observation

@MainActor @Observable final class ProfileManager: ProfileFeature {
  private(set) var facts: [PersonalFactSnapshot] = []
  private(set) var loadError: String?
  private(set) var isLoading = false
  private var loaded = false
  private let repository: any PersonalDataRepository
  private let now: @Sendable () -> Date
  private let operations = FIFOOperationGate()
  init(repository: any PersonalDataRepository, now: @escaping @Sendable () -> Date) {
    self.repository = repository
    self.now = now
  }

  func canSave(label: String, value: String) -> Bool {
    !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  func loadIfRequired() async { if !loaded { await refresh() } }
  func refresh() async {
    await operations.acquire()
    defer { operations.release() }
    guard !Task.isCancelled else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      facts = try await repository.loadFacts()
      loaded = true
      loadError = nil
    } catch { loadError = error.localizedDescription }
  }
  func addFact(label: String, value: String) async throws {
    guard canSave(label: label, value: value) else { throw ProfileError.emptyFact }
    await operations.acquire()
    defer { operations.release() }
    try Task.checkCancellation()
    let fact = PersonalFactSnapshot(id: UUID(), label: label, value: value, createdAt: now())
    try await repository.saveFact(fact)
    facts.insert(fact, at: 0)
  }
}
