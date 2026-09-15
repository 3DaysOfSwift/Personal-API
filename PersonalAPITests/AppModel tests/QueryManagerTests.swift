import XCTest
#if canImport(FoundationModels)
import FoundationModels
#endif
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

private actor ContextSearchCapture: SemanticMomentSearching {
    var questions: [String] = []
    func match(question: String, moments: [MomentSnapshot]) async throws -> [UUID] {
        questions.append(question)
        return moments.map(\.id)
    }
}
private struct SourceAnswer: MomentAnswering {
    func answer(question: String, evidence: [Evidence]) async throws -> GroundedAnswer? {
        GroundedAnswer(text: evidence.map { $0.moment.text }.joined(separator: " "), citations: [])
    }
}
private struct PassageStub: SemanticMomentSearching {
    let passages: [SearchPassage]
    func match(question: String, moments: [MomentSnapshot]) async throws -> [UUID] { passages.map(\.momentID) }
    func selectPassages(question: String, moments: [MomentSnapshot]) async throws -> [SearchPassage] { passages }
}
private struct ContextAnswer: MomentAnswering {
    func answer(question: String, evidence: [Evidence]) async throws -> GroundedAnswer? {
        GroundedAnswer(text: AnswerContext(evidence: evidence).passages.map(\.text).joined(separator: " "), citations: [])
    }
}
@MainActor final class QueryManagerTests: XCTestCase {
    func testChatContextIsBoundedAndRetryReadsNewJournalEvidence() async throws {
        let repository = MemoryRepository()
        let search = ContextSearchCapture()
        let query = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: search, answerer: SourceAnswer())
        let original = moment("I attended school.")
        try await repository.saveMoment(original)
        let chats = ConversationsManager(repository: MemoryConversationRepository(), query: query, now: { Date() })
        let id = UUID()
        try await chats.send("Did I enjoy school?", in: id)
        try await repository.saveMoment(moment("I enjoyed the art lessons."))
        try await chats.answerAgain(in: id)
        XCTAssertTrue(chats.conversations.first!.turns.last!.result!.generatedAnswer!.text.contains("art lessons"))
        let stored = try await repository.loadMoments()
        XCTAssertEqual(stored.count, 2)
        try await chats.delete(id)
        let afterDeletion = try await repository.loadMoments()
        XCTAssertEqual(afterDeletion, stored)
        _ = try await query.search("Did I enjoy it?", previousQuestions: ["old"] + Array(repeating: String(repeating: "q", count: 600), count: 4))
        let payload = await search.questions.last!
        let json = try JSONDecoder().decode([String: [String]].self, from: Data(payload.utf8))
        XCTAssertEqual(json["currentQuestion"], ["Did I enjoy it?"])
        XCTAssertEqual(json["previousQuestions"]?.count, 4)
        XCTAssertTrue(json["previousQuestions"]!.allSatisfy { $0.count == 500 })
    }
    func testRelevantTailReachesAnswerInsteadOfUnrelatedEntryBeginning() async throws {
        let relevant = "I don’t remember disliking school, but I felt confused about the lessons."
        let source = moment(String(repeating: "An unrelated memory. ", count: 200) + relevant)
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let search = PassageStub(passages: [SearchPassage(momentID: source.id, text: relevant)])
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: search, answerer: ContextAnswer())
        let result = try await manager.search("Did I enjoy school?")
        XCTAssertEqual(result.generatedAnswer?.text, relevant)
        XCTAssertEqual(result.evidence.first?.moment.text, source.text)
        XCTAssertEqual(result.evidence.first?.passages, [relevant])
    }
    func testInventedPassageCannotBecomeAnswerEvidence() async throws {
        let source = moment("I attended school.")
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let search = PassageStub(passages: [SearchPassage(momentID: source.id, text: "I loved school.")])
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: search, answerer: ContextAnswer())
        let result = try await manager.search("school")
        XCTAssertNil(result.generatedAnswer)
        guard case .keywords = result.method else { return XCTFail("Reject invented text") }
    }
    func testContextPreservesWholeQualificationAndReportsOmission() {
        let text = "I remember liking the games, but not the lessons."
        let source = moment(text)
        let context = AnswerContext(evidence: [Evidence(moment: source, score: 1, passages: [text])], characterBudget: text.count - 1)
        XCTAssertTrue(context.passages.isEmpty)
        XCTAssertTrue(context.limited)
        let complete = AnswerContext(evidence: [Evidence(moment: source, score: 1, passages: [text])])
        XCTAssertEqual(complete.passages.first?.text, text)
        XCTAssertFalse(complete.limited)
    }
    func testOlderSavedEvidenceWithoutPassagesStillDecodes() throws {
        let evidence = Evidence(moment: moment("Original memory"), score: 1)
        let data = try JSONEncoder().encode(evidence)
        let decoded = try JSONDecoder().decode(Evidence.self, from: data)
        XCTAssertNil(decoded.passages)
        XCTAssertEqual(AnswerContext(evidence: [decoded]).passages.first?.text, "Original memory")
    }
    private func moment(_ text: String) -> MomentSnapshot {
        MomentSnapshot(id: UUID(), text: text, createdAt: Date(), happenedAt: nil,
                       source: "journal", analysisData: nil, processingState: "pending")
    }
    func testModelRefusalsAndGuardrailsAreNotRetried() throws {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let context = LanguageModelSession.GenerationError.Context(debugDescription: "test")
            XCTAssertFalse(isTemporaryModelFailure(LanguageModelSession.GenerationError.guardrailViolation(context)))
            XCTAssertFalse(isTemporaryModelFailure(LanguageModelSession.GenerationError.refusal(.init(transcriptEntries: []), context)))
            XCTAssertTrue(isTemporaryModelFailure(LanguageModelSession.GenerationError.rateLimited(context)))
        }
        #endif
    }
    func testTemporaryFailureRetriesOnceAndReturnsAnswer() async throws {
        var calls = 0
        let result: String = try await withLocalModelRetry(pause: {}) {
            calls += 1
            if calls == 1 { throw NSError(domain: NSCocoaErrorDomain, code: 4097) }
            return "Recovered answer"
        }
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(result, "Recovered answer")
    }
    func testRetryStopsAfterSecondTemporaryFailure() async {
        var calls = 0
        do {
            let _: String = try await withLocalModelRetry(pause: {}) {
                calls += 1
                throw NSError(domain: NSCocoaErrorDomain, code: 4099)
            }
            XCTFail("Expected failure")
        } catch { XCTAssertEqual(calls, 2) }
    }
    func testPermanentFailureIsNotRetried() async {
        var calls = 0
        do {
            let _: String = try await withLocalModelRetry(pause: {}) {
                calls += 1
                throw QueryFailure.unavailable("Not eligible")
            }
            XCTFail("Expected failure")
        } catch { XCTAssertEqual(calls, 1) }
    }
    func testCancellationDuringBackoffPreventsSecondAttempt() async {
        var calls = 0
        do {
            let _: String = try await withLocalModelRetry(pause: { throw CancellationError() }) {
                calls += 1
                throw NSError(domain: NSCocoaErrorDomain, code: 4097)
            }
            XCTFail("Expected cancellation")
        } catch is CancellationError { XCTAssertEqual(calls, 1) }
        catch { XCTFail("Expected cancellation, got \(error)") }
    }
    func testConversationalAnswerDoesNotRequireGeneratedQuotations() async throws {
        let source = moment("Alex is my school friend.")
        let repository = MemoryRepository(); try await repository.saveMoment(source)
        let answer = GroundedAnswer(text: "Alex is your school friend.", citations: [])
        let manager = QueryManager(repository: repository, retriever: MomentRetriever(), semanticSearch: SearchStub(ids: [source.id]), answerer: AnswerStub(result: answer))
        let result = try await manager.search("Who is Alex?")
        XCTAssertEqual(result.generatedAnswer?.text, answer.text)
        XCTAssertNil(result.answerIssue)
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
        XCTAssertTrue(result.needsMoreMemories)
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
        XCTAssertFalse(result.needsMoreMemories)
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
        XCTAssertTrue(result.needsMoreMemories)
    }
}
