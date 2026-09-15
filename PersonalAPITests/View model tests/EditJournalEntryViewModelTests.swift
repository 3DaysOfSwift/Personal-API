import XCTest
@testable import PersonalAPI

@MainActor final class EditJournalEntryViewModelTests: XCTestCase {
    func testFailedSaveKeepsDraftAndCanRetry() async throws {
        let graph = TestAppModelFactory()
        try await graph.app.momentsFeature.recordMoment(text: "Original", happenedAt: nil)
        await graph.app.momentsFeature.enrichPendingMoments()
        let original = try XCTUnwrap(graph.app.momentsFeature.moments.first)
        let model = EditJournalEntryViewModel(moments: graph.app.momentsFeature)
        model.prepare(original)
        model.text = "Revised"
        model.prepare(original)
        await graph.repository.setFailure(true)
        let failed = await model.save()
        XCTAssertFalse(failed)
        XCTAssertEqual(model.text, "Revised")
        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.isWorking)
        await graph.repository.setFailure(false)
        let saved = await model.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(graph.app.momentsFeature.moments.first?.text, "Revised")
    }
}
