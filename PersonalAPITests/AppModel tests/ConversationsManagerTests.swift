import XCTest
@testable import PersonalAPI

@MainActor final class ConversationQueryStub: QueryFeature {
    var contexts: [[String]] = []
    var answer = "Your recorded answer."
    var deferred = false
    var pending: CheckedContinuation<QueryResult, Error>?
    func canSearch(_ question: String) -> Bool { !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func search(_ question: String) async throws -> QueryResult { try await search(question, previousQuestions: []) }
    func search(_ question: String, previousQuestions: [String]) async throws -> QueryResult {
        contexts.append(previousQuestions)
        if deferred { return try await withCheckedThrowingContinuation { pending = $0 } }
        return QueryResult(evidence: [], searchedCount: 0, generatedAnswer: GroundedAnswer(text: answer, citations: []), method: .onDeviceAI)
    }
}
@MainActor final class ConversationsManagerTests: XCTestCase {
    func testFollowUpUsesQuestionsNeverGeneratedAnswersAndNewChatIsIsolated() async throws {
        let query = ConversationQueryStub()
        let manager = ConversationsManager(repository: MemoryConversationRepository(), query: query, now: { Date() })
        let id = UUID()
        try await manager.send("Who was Alex?", in: id)
        try await manager.send("Where did I meet him?", in: id)
        XCTAssertEqual(query.contexts, [[], ["Who was Alex?"]])
        XCTAssertEqual(manager.conversations.first?.turns.count, 2)
        try await manager.send("Where?", in: UUID())
        XCTAssertEqual(query.contexts.last, [])
    }
    func testRetryReplacesLatestAnswerAndRetrievesAgainWithoutDuplicatingQuestion() async throws {
        let query = ConversationQueryStub()
        let manager = ConversationsManager(repository: MemoryConversationRepository(), query: query, now: { Date() })
        let id = UUID()
        try await manager.send("Did I enjoy school?", in: id)
        query.answer = "You remember enjoying it."
        try await manager.answerAgain(in: id)
        XCTAssertEqual(query.contexts.count, 2)
        XCTAssertEqual(manager.conversations.first?.turns.count, 1)
        XCTAssertEqual(manager.conversations.first?.turns.first?.result?.generatedAnswer?.text, query.answer)
    }
    func testCancellationKeepsSavedQuestionAndDiscardsLateAnswer() async throws {
        let query = ConversationQueryStub(); query.deferred = true
        let store = MemoryConversationRepository()
        let manager = ConversationsManager(repository: store, query: query, now: { Date() })
        let operation = Task { try await manager.send("Who?", in: UUID()) }
        while query.pending == nil { await Task.yield() }
        operation.cancel()
        query.pending?.resume(returning: QueryResult(evidence: [], searchedCount: 0))
        do { try await operation.value; XCTFail("Expected cancellation") } catch is CancellationError { }
        XCTAssertNil(manager.conversations.first?.turns.first?.result)
        XCTAssertEqual(manager.conversations.first?.turns.first?.question, "Who?")
        XCTAssertFalse(manager.isBusy)
    }
    func testSaveFailureDoesNotPublishOrCallAI() async throws {
        let store = MemoryConversationRepository()
        let query = ConversationQueryStub()
        let manager = ConversationsManager(repository: store, query: query, now: { Date() })
        try await manager.load()
        await store.setFailure(true)
        do { try await manager.send("Who?", in: UUID()); XCTFail("Expected failure") } catch { }
        XCTAssertTrue(manager.conversations.isEmpty)
        XCTAssertTrue(query.contexts.isEmpty)
    }
    func testFeedbackSurvivesReloadAndDeletionDoesNotTouchJournal() async throws {
        let store = MemoryConversationRepository()
        let query = ConversationQueryStub()
        let manager = ConversationsManager(repository: store, query: query, now: { Date() })
        let id = UUID()
        try await manager.send("Who?", in: id)
        let turn = try XCTUnwrap(manager.conversations.first?.turns.first)
        try await manager.recordFeedback(.inventedDetail, explanation: "Never recorded that.", turnID: turn.id, conversationID: id)
        let reloaded = ConversationsManager(repository: store, query: query, now: { Date() })
        try await reloaded.load()
        XCTAssertEqual(reloaded.conversations.first?.turns.first?.feedback?.explanation, "Never recorded that.")
        try await reloaded.delete(id)
        XCTAssertTrue(reloaded.conversations.isEmpty)
        XCTAssertEqual(query.contexts.count, 1)
    }
    func testLocalArchiveRoundTripAndCorruptFileIsNotReset() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("chats.json")
        let store = LocalConversationStore(url: url)
        let manager = ConversationsManager(repository: store, query: ConversationQueryStub(), now: { Date() })
        let id = UUID()
        try await manager.send("My question", in: id)
        let loaded = try await LocalConversationStore(url: url).load()
        XCTAssertEqual(loaded.first?.id, id)
        XCTAssertEqual(loaded.first?.turns.first?.result?.generatedAnswer?.text, "Your recorded answer.")
        let exported = try await manager.export()
        XCTAssertTrue(String(decoding: exported, as: UTF8.self).contains("My question"))
        try Data("broken".utf8).write(to: url)
        do { _ = try await LocalConversationStore(url: url).load(); XCTFail("Expected decoding error") } catch { }
        XCTAssertEqual(try String(contentsOf: url), "broken")
    }
}
