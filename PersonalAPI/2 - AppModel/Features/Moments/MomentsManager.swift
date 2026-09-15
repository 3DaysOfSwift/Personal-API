import Foundation
import Observation

@MainActor @Observable final class MomentsManager: MomentsFeature {
    private(set) var moments: [MomentSnapshot] = []
    private(set) var isLoading = false
    private(set) var loadError: String?
    private(set) var enrichmentError: String?
    private var loaded = false
    private let repository: any PersonalDataRepository
    private let processor: any MomentProcessor
    private let factExtractor: any JournalFactExtracting
    private var indexedSources: [UUID: String] = [:]
    private let now: @Sendable () -> Date
    private var enrichmentTask: Task<Void, Never>?
    private var busy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(repository: any PersonalDataRepository, processor: any MomentProcessor, now: @escaping @Sendable () -> Date, factExtractor: (any JournalFactExtracting)? = nil) {
        self.repository = repository; self.processor = processor; self.now = now
        self.factExtractor = factExtractor ?? LocalJournalFactExtractor(now: now)
    }
    // Serialise persistence AND publication across suspension, preventing stale refreshes.
    private func acquire() async {
        if !busy { busy = true; return }
        await withCheckedContinuation { waiters.append($0) }
    }
    private func release() {
        if waiters.isEmpty { busy = false } else { waiters.removeFirst().resume() }
    }
    func currentMoment(_ fallback: MomentSnapshot) -> MomentSnapshot {
        moments.first(where: { $0.id == fallback.id }) ?? fallback
    }
    func canRecord(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func loadIfRequired() async {
        guard !loaded else { return }
        await refresh()
    }
    func refresh() async {
        await acquire()
        defer { release() }
        // Cancellation before a read leaves previously published state intact.
        guard !Task.isCancelled else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            moments = try await repository.loadMoments()
            loaded = true; loadError = nil
            requestEnrichment()
        } catch { loadError = error.localizedDescription }
    }
    func recordMoment(text: String, happenedAt: Date?) async throws {
        guard canRecord(text) else { throw MomentError.emptyMoment }
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        let moment = MomentSnapshot(id: UUID(), text: text, createdAt: now(), happenedAt: happenedAt,
                                    source: "manual", analysisData: nil, processingState: "pending")
        try await repository.saveMoment(moment)
        // A committed source must publish even if cancellation arrived during the save.
        moments.insert(moment, at: 0)
        requestEnrichment()
    }
    private func requestEnrichment() {
        guard enrichmentTask == nil else { return }
        enrichmentTask = Task { [self] in
            await analysePendingSources()
            enrichmentTask = nil
        }
    }
    func enrichPendingMoments() async {
        requestEnrichment()
        await enrichmentTask?.value
    }
    private func analysePendingSources() async {
        var attempted: Set<UUID> = []
        enrichmentError = nil
        while let moment = moments.first(where: {
            ($0.processingState != "complete" || indexedSources[$0.id] != $0.text) && !attempted.contains($0.id)
        }) {
            attempted.insert(moment.id)
            if moment.processingState != "complete" {
                do {
                    let result = try await processor.analyse(MomentInput(text: moment.text, createdAt: moment.createdAt))
                    await acquire()
                    do {
                        let updated = try await repository.saveAnalysis(result, momentID: moment.id)
                        if let index = moments.firstIndex(where: { $0.id == moment.id }) { moments[index] = updated }
                        release()
                    } catch { release(); throw error }
                } catch {
                    enrichmentError = "Your original text is saved. Metadata needs a retry: \(error.localizedDescription)"
                }
            }
            do {
                let facts = try await factExtractor.extract(from: moment)
                try await repository.replaceDerivedFacts(facts, source: moment)
                indexedSources[moment.id] = moment.text
            } catch {
                enrichmentError = "Your original text is saved. Search indexing needs a retry: \(error.localizedDescription)"
            }
        }
    }
    func regenerateMetadata() async throws {
        // Finish the old pass before marking data pending, so it cannot erase this request.
        await enrichmentTask?.value
        await acquire()
        do {
            try Task.checkCancellation()
            moments = try await repository.markAnalysesPending()
            release()
        } catch { release(); throw error }
        indexedSources.removeAll()
        await enrichPendingMoments()
    }
}
