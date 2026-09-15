import XCTest
@testable import PersonalAPI
@MainActor final class MomentsManagerTests: XCTestCase {
    func testEnrichmentFailurePreservesCommittedSource() async throws {
        let graph = TestAppModelFactory(processor: FailingProcessor())
        try await graph.app.momentsFeature.recordMoment(text: "Dad called yesterday", happenedAt: nil)
        await graph.app.momentsFeature.enrichPendingMoments()
        let stored = try await graph.repository.loadMoments()
        XCTAssertEqual(stored.first?.text, "Dad called yesterday")
        XCTAssertEqual(stored.first?.processingState, "pending")
        XCTAssertNotNil(graph.app.momentsFeature.enrichmentError)
    }
    func testConcurrentSavesAndRefreshKeepBothSources() async throws {
        let graph = TestAppModelFactory()
        async let first: Void = graph.app.momentsFeature.recordMoment(text: "first", happenedAt: nil)
        async let second: Void = graph.app.momentsFeature.recordMoment(text: "second", happenedAt: nil)
        async let refresh: Void = graph.app.momentsFeature.refresh()
        _ = try await (first, second, refresh)
        await graph.app.momentsFeature.enrichPendingMoments()
        XCTAssertEqual(Set(graph.app.momentsFeature.moments.map(\.text)), ["first", "second"])
        XCTAssertEqual(Set(graph.app.momentsFeature.moments.map(\.createdAt)), [Date(timeIntervalSince1970: 1_000)])
    }
    func testFailedLoadCanRetryWithoutResettingStore() async {
        let graph = TestAppModelFactory()
        await graph.repository.setFailure(true)
        await graph.app.momentsFeature.loadIfRequired()
        XCTAssertNotNil(graph.app.momentsFeature.loadError)
        await graph.repository.setFailure(false)
        await graph.app.momentsFeature.loadIfRequired()
        XCTAssertNil(graph.app.momentsFeature.loadError)
    }
    func testCancelledSaveDoesNotPersist() async {
        let graph = TestAppModelFactory()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do { try await graph.app.momentsFeature.recordMoment(text: "cancelled", happenedAt: nil); XCTFail("Expected cancellation") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        await task.value
        XCTAssertTrue(graph.app.momentsFeature.moments.isEmpty)
    }
}

private actor RetryFactExtractor: JournalFactExtracting {
    var fails = true
    func allowExtraction() { fails = false }
    func extract(from moment: MomentSnapshot) async throws -> [PersonalFactSnapshot] {
        if fails { throw TestFailure.unavailable }
        return try await LocalJournalFactExtractor(now: { Date(timeIntervalSince1970: 100) }).extract(from: moment)
    }
}

extension MomentsManagerTests {
    func testAutomaticFactsPreserveQualificationsAndBackfillCompletedEntries() async throws {
        let repository = MemoryRepository()
        let text = "I worked as a teacher in 2012, but no longer do.\nI love making apps, although deadlines can be stressful."
        let source = MomentSnapshot(id: UUID(), text: text, createdAt: Date(), happenedAt: nil,
            source: "manual", analysisData: nil, processingState: "complete")
        try await repository.saveMoment(source)
        let manager = MomentsManager(repository: repository, processor: FailingProcessor(), now: { Date() })
        await manager.refresh()
        await manager.enrichPendingMoments()
        let facts = try await repository.loadFacts()
        XCTAssertEqual(Set(facts.map(\.value)), Set(text.components(separatedBy: "\n")))
        XCTAssertTrue(facts.allSatisfy { $0.isSupported(by: source) })
        XCTAssertNil(manager.enrichmentError)
        await manager.enrichPendingMoments()
        let again = try await repository.loadFacts()
        XCTAssertEqual(again, facts)
    }

    func testExtractionFailureDoesNotLoseJournalAndCanRetry() async throws {
        let repository = MemoryRepository()
        let extractor = RetryFactExtractor()
        let manager = MomentsManager(repository: repository, processor: LocalMomentProcessor(now: { Date() }),
            now: { Date() }, factExtractor: extractor)
        try await manager.recordMoment(text: "My job is an iOS developer.", happenedAt: nil)
        await manager.enrichPendingMoments()
        let saved = try await repository.loadMoments()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.text, "My job is an iOS developer.")
        XCTAssertNotNil(manager.enrichmentError)
        await extractor.allowExtraction()
        await manager.enrichPendingMoments()
        let facts = try await repository.loadFacts()
        XCTAssertEqual(facts.count, 1)
        XCTAssertNil(manager.enrichmentError)
    }

    func testExtractionDoesNotInferFromUnrelatedTextOrTruncateLongQualifications() async throws {
        let text = "Alice is an engineer.\n" + String(repeating: "I like music but ", count: 60) + "this is fiction."
        let source = MomentSnapshot(id: UUID(), text: text, createdAt: Date(), happenedAt: nil,
            source: "manual", analysisData: nil, processingState: "pending")
        let facts = try await LocalJournalFactExtractor(now: { Date() }).extract(from: source)
        XCTAssertTrue(facts.isEmpty)
    }
}
