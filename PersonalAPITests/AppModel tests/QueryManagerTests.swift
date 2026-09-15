import XCTest
@testable import PersonalAPI

private struct SearchStub: SemanticMomentSearching {
    let ids: [UUID]
    var failure: QueryFailure? = nil
    var cancel = false
    func match(question: String, moments: [MomentSnapshot]) async throws -> [UUID] {
        if cancel { throw CancellationError() }
        if let failure { throw failure }
        return ids
    }
}

private struct AnswerStub: MomentAnswering {
    let result: GroundedAnswer?
    func answer(question: String, evidence: [Evidence]) async throws -> GroundedAnswer? { result }
}

@MainActor final class QueryManagerTests: XCTestCase {
    private func moment(_ text: String) -> MomentSnapshot {
        MomentSnapshot(id: UUID(), text: text, createdAt: Date(), happenedAt: nil,
                       source: "journal", analysisData: nil, processingState: "pending")
    }
    func testSupportedAnswerIsReturnedWithOriginalEvidence() async throws {
        let source = moment("Alex is my school friend.")
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let answer = GroundedAnswer(text: "Alex is your school friend.", citations: [AnswerCitation(momentID: source.id, quote: source.text)])
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [source.id]), answerer: AnswerStub(result: answer))
        let result = try await manager.search("Who is Alex?")
        XCTAssertEqual(result.generatedAnswer?.text, answer.text)
        XCTAssertEqual(result.evidence.first?.moment, source)
        XCTAssertNil(result.answerIssue)
    }
    func testInventedQuoteRejectsAnswerButRetainsRetrievedMoments() async throws {
        let source = moment("Alex is my school friend.")
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let answer = GroundedAnswer(text: "Alex is your brother.", citations: [AnswerCitation(momentID: source.id, quote: "Alex is my brother")])
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [source.id]), answerer: AnswerStub(result: answer))
        let result = try await manager.search("Who is Alex?")
        XCTAssertNil(result.generatedAnswer)
        XCTAssertNotNil(result.answerIssue)
        XCTAssertEqual(result.method, .onDeviceAI)
        XCTAssertEqual(result.evidence.first?.id, source.id)
    }
    func testAnswerAbstentionRetainsSourcesAndExplainsInsufficientEvidence() async throws {
        let source = moment("I saw Alex.")
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [source.id]), answerer: AnswerStub(result: nil))
        let result = try await manager.search("Where does Alex live?")
        XCTAssertNil(result.generatedAnswer)
        XCTAssertNotNil(result.answerIssue)
        XCTAssertEqual(result.evidence.count, 1)
    }
    func testOnDeviceModelWithSyntheticJournalWhenRequested() async throws {
        guard ProcessInfo.processInfo.environment["PERSONAL_API_LIVE_AI_TEST"] == "1" else {
            throw XCTSkip("Opt-in local model evaluation; uses synthetic entries only")
        }
        let exercise = moment("I went jogging for half an hour before breakfast.")
        let unrelated = moment("I bought blue curtains for the living room.")
        let ids = try await OnDeviceMomentSearch().match(question: "When did I exercise?", moments: [exercise, unrelated])
        XCTAssertTrue(ids.contains(exercise.id))
        XCTAssertFalse(ids.contains(unrelated.id))
    }
    func testSemanticMatchDoesNotRequireKeywordOverlapAndPreservesOriginal() async throws {
        let repository = MemoryRepository()
        let original = moment("I went jogging before sunrise.")
        try await repository.saveMoment(original)
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [original.id, original.id]))
        let result = try await manager.search("exercise")
        XCTAssertEqual(result.method, .onDeviceAI)
        XCTAssertEqual(result.evidence.map(\.moment), [original])
        let stored = try await repository.loadMoments()
        XCTAssertEqual(stored, [original])
    }
    func testUnavailableModelReturnsClearlyLabelledKeywordFallback() async throws {
        let repository = MemoryRepository(); let source = moment("garden idea")
        try await repository.saveMoment(source)
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [], failure: .unavailable("Model not ready")))
        let result = try await manager.search("garden")
        XCTAssertEqual(result.method, .keywords(reason: "Model not ready"))
        XCTAssertEqual(result.evidence.first?.id, source.id)
    }
    func testInventedSourceIDCannotBecomeEvidence() async throws {
        let repository = MemoryRepository(); try await repository.saveMoment(moment("jogging"))
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [UUID()]))
        let result = try await manager.search("exercise")
        XCTAssertTrue(result.evidence.isEmpty)
        guard case .keywords = result.method else { return XCTFail("Must reject invalid AI references") }
    }
    func testCancellationDoesNotStartFallback() async throws {
        let manager = QueryManager(repository: MemoryRepository(), retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [], cancel: true))
        do { _ = try await manager.search("garden"); XCTFail("Expected cancellation") }
        catch is CancellationError { }
    }
    func testLongEntriesIncludeEndAndOverlapWithoutChangingSource() {
        let source = moment(String(repeating: "a", count: 2600) + "last detail")
        let passages = SearchPassage.split([source])
        XCTAssertTrue(passages.last!.text.hasSuffix("last detail"))
        XCTAssertTrue(passages.allSatisfy { $0.text.count <= 1200 && $0.momentID == source.id })
        XCTAssertEqual(String(passages[0].text.suffix(200)), String(passages[1].text.prefix(200)))
    }
    func testAIAbstentionStaysEmptyEvenWithKeywordOverlap() async throws {
        let repository = MemoryRepository(); try await repository.saveMoment(moment("garden"))
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: []))
        let result = try await manager.search("garden")
        XCTAssertEqual(result.method, .onDeviceAI)
        XCTAssertTrue(result.evidence.isEmpty)
    }
}
