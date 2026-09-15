import XCTest
@testable import PersonalAPI
@MainActor private final class DeferredQuery: QueryFeature {
    var pending: [String: CheckedContinuation<QueryResult, Error>] = [:]
    func canSearch(_ question: String) -> Bool { true }
    func search(_ question: String) async throws -> QueryResult {
        try await withCheckedThrowingContinuation { pending[question] = $0 }
    }
}
@MainActor final class QueryViewModelTests: XCTestCase {
    func testAnswerFailureIsTheResponseNotAMatchCount() async {
        let query = DeferredQuery(); let vm = QueryViewModel(query: query)
        vm.question = "Who is Alex?"
        let task = Task { await vm.search() }
        while query.pending[vm.question] == nil { await Task.yield() }
        query.pending.removeValue(forKey: vm.question)?.resume(returning: QueryResult(evidence: [], searchedCount: 1, answerIssue: "The model declined this question.", method: .onDeviceAI))
        await task.value
        XCTAssertEqual(vm.answer, "The model declined this question.")
        XCTAssertFalse(vm.hasAIAnswer)
    }
    func testGeneratedAnswerIsDisplayedInsteadOfMatchCountMessage() async {
        let query = DeferredQuery(); let vm = QueryViewModel(query: query)
        vm.question = "Who is Alex?"
        let task = Task { await vm.search() }
        while query.pending[vm.question] == nil { await Task.yield() }
        let generated = GroundedAnswer(text: "Alex is your school friend.", citations: [])
        query.pending.removeValue(forKey: vm.question)?.resume(returning: QueryResult(evidence: [], searchedCount: 1, generatedAnswer: generated, method: .onDeviceAI))
        await task.value
        XCTAssertEqual(vm.answer, generated.text)
        XCTAssertTrue(vm.hasAIAnswer)
    }
    func testKeywordEvidenceAndAbstention() async throws {
        let graph = TestAppModelFactory()
        try await graph.app.momentsFeature.recordMoment(text: "garden idea", happenedAt: nil)
        let vm = QueryViewModel(query: graph.app.queryFeature)
        vm.question = "garden"; await vm.search()
        XCTAssertEqual(vm.results.first?.moment.text, "garden idea")
        vm.question = "hospital"; await vm.search()
        XCTAssertTrue(vm.searched); XCTAssertTrue(vm.results.isEmpty)
        await graph.app.momentsFeature.enrichPendingMoments()
    }
    func testOldCompletionCannotReplaceNewSearch() async {
        let query = DeferredQuery()
        let vm = QueryViewModel(query: query)
        vm.question = "old"
        let old = Task { await vm.search() }
        while query.pending["old"] == nil { await Task.yield() }
        vm.question = "new"
        let new = Task { await vm.search() }
        while query.pending["new"] == nil { await Task.yield() }
        query.pending.removeValue(forKey: "new")?.resume(returning: QueryResult(evidence: [], searchedCount: 2))
        await new.value
        query.pending.removeValue(forKey: "old")?.resume(returning: QueryResult(evidence: [], searchedCount: 1))
        await old.value
        XCTAssertEqual(vm.searchedCount, 2)
        XCTAssertEqual(vm.submitted, "new")
    }
    func testDisappearingScreenDiscardsCompletion() async {
        let query = DeferredQuery()
        let vm = QueryViewModel(query: query)
        vm.question = "old"
        let request = Task { await vm.search() }
        while query.pending["old"] == nil { await Task.yield() }
        vm.cancelSearch()
        query.pending.removeValue(forKey: "old")?.resume(returning: QueryResult(evidence: [], searchedCount: 1))
        await request.value
        XCTAssertFalse(vm.searched)
        XCTAssertFalse(vm.isSearching)
    }
}
