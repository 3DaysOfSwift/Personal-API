import XCTest
@testable import PersonalAPI

@MainActor final class QueryViewModelTests: XCTestCase {
    func testMessagesRemainAndComposerClearsAfterSend() async throws {
        let manager = ConversationsManager(repository: MemoryConversationRepository(), query: ConversationQueryStub(), now: { Date() })
        let vm = QueryViewModel(chats: manager)
        await vm.load()
        vm.question = "Who was Alex?"
        await vm.sendDraft()
        vm.question = "Where did we meet?"
        await vm.sendDraft()
        XCTAssertEqual(vm.turns.count, 2)
        XCTAssertEqual(vm.question, "")
        XCTAssertEqual(vm.answer(for: vm.turns[0]), "Your recorded answer.")
    }
    func testFreshLaunchStartsNewChatAndKeepsHistoryAvailable() async throws {
        let store = MemoryConversationRepository()
        let previous = ConversationsManager(repository: store, query: ConversationQueryStub(), now: { Date() })
        let savedID = UUID()
        try await previous.send("Previous conversation", in: savedID)
        let relaunched = ConversationsManager(repository: store, query: ConversationQueryStub(), now: { Date() })
        let vm = QueryViewModel(chats: relaunched)
        await vm.load()
        XCTAssertNotEqual(vm.conversationID, savedID)
        XCTAssertTrue(vm.turns.isEmpty)
        XCTAssertTrue(vm.question.isEmpty)
        XCTAssertEqual(vm.conversations.count, 1)
        vm.open(savedID)
        await vm.load()
        XCTAssertEqual(vm.conversationID, savedID)
        XCTAssertEqual(vm.turns.first?.question, "Previous conversation")
    }
    func testFailedSaveKeepsDraft() async {
        let store = MemoryConversationRepository()
        let vm = QueryViewModel(chats: ConversationsManager(repository: store, query: ConversationQueryStub(), now: { Date() }))
        await vm.load()
        await store.setFailure(true)
        vm.question = "Keep this question"
        await vm.sendDraft()
        XCTAssertEqual(vm.question, "Keep this question")
        XCTAssertNotNil(vm.error)
        XCTAssertTrue(vm.turns.isEmpty)
    }
    func testNewChatAndReopenPreserveHistory() async {
        let vm = QueryViewModel(chats: ConversationsManager(repository: MemoryConversationRepository(), query: ConversationQueryStub(), now: { Date() }))
        vm.question = "First chat"
        await vm.sendDraft()
        let original = vm.conversationID
        vm.newChat()
        XCTAssertTrue(vm.turns.isEmpty)
        vm.open(original)
        XCTAssertEqual(vm.turns.first?.question, "First chat")
    }
    func testFailureAndMissingEvidenceDisplayDistinctly() {
        let vm = QueryViewModel(chats: ConversationsManager(repository: MemoryConversationRepository(), query: ConversationQueryStub(), now: { Date() }))
        let failed = ChatTurn(id: UUID(), question: "Who?", createdAt: Date(), failure: "Model unavailable")
        let missing = ChatTurn(id: UUID(), question: "Who?", createdAt: Date(),
            result: QueryResult(evidence: [], searchedCount: 1, needsMoreMemories: true, method: .onDeviceAI))
        XCTAssertEqual(vm.answer(for: failed), "Model unavailable")
        XCTAssertTrue(vm.answer(for: missing).contains("enough information"))
    }
}
