import XCTest
@testable import PersonalAPI

@MainActor final class JournalEntriesViewModelTests: XCTestCase {
    func testListReflectsDeletionThroughSharedFeature() async throws {
        let graph = TestAppModelFactory()
        try await graph.app.momentsFeature.recordMoment(text: "An entry", happenedAt: nil)
        await graph.app.momentsFeature.enrichPendingMoments()
        let model = JournalEntriesViewModel(moments: graph.app.momentsFeature)
        await model.refresh()
        XCTAssertEqual(model.entries.count, 1)
        try await graph.app.momentsFeature.deleteMoment(XCTUnwrap(model.entries.first))
        XCTAssertTrue(model.entries.isEmpty)
    }
}
