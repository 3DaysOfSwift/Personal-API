import Foundation
import Observation
@MainActor @Observable final class ProfileManager: ProfileFeature {
    private(set) var facts: [PersonalFactSnapshot] = []
    private(set) var loadError: String?
    private(set) var isLoading = false
    private var loaded = false
    private let repository: any PersonalDataRepository
    private let now: @Sendable () -> Date
    private var busy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    init(repository: any PersonalDataRepository, now: @escaping @Sendable () -> Date) { self.repository = repository; self.now = now }
    private func acquire() async {
        if !busy { busy = true; return }
        await withCheckedContinuation { waiters.append($0) }
    }
    private func release() {
        if waiters.isEmpty { busy = false } else { waiters.removeFirst().resume() }
    }
    func canSave(label: String, value: String) -> Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    func loadIfRequired() async { if !loaded { await refresh() } }
    func refresh() async {
        await acquire(); defer { release() }
        guard !Task.isCancelled else { return }
        isLoading = true; defer { isLoading = false }
        do { facts = try await repository.loadFacts(); loaded = true; loadError = nil }
        catch { loadError = error.localizedDescription }
    }
    func addFact(label: String, value: String) async throws {
        guard canSave(label: label, value: value) else { throw ProfileError.emptyFact }
        await acquire(); defer { release() }
        try Task.checkCancellation()
        let fact = PersonalFactSnapshot(id: UUID(), label: label, value: value, createdAt: now())
        try await repository.saveFact(fact)
        facts.insert(fact, at: 0)
    }
}
