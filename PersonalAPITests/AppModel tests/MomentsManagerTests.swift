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
