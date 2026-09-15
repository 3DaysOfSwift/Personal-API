import Foundation
struct Evidence: Identifiable, Codable, Sendable {
    let moment: MomentSnapshot
    let score: Int
    var passages: [String]? = nil
    var id: UUID { moment.id }
}
enum RetrievalOutcome: Sendable { case noEvidence, matches }
struct QueryResult: Codable, Sendable {
    var outcome: RetrievalOutcome { evidence.isEmpty ? .noEvidence : .matches }
    let evidence: [Evidence]
    let searchedCount: Int
    var needsMoreMemories = false
    var generatedAnswer: GroundedAnswer? = nil
    var answerIssue: String? = nil
    var method: SearchMethod = .keywords(reason: nil)
}
@MainActor protocol QueryFeature: AnyObject, Sendable {
    func canSearch(_ question: String) -> Bool
    func search(_ question: String) async throws -> QueryResult
    func search(_ question: String, previousQuestions: [String]) async throws -> QueryResult
}

enum SearchMethod: Codable, Sendable, Equatable {
    case onDeviceAI
    case keywords(reason: String?)
}

struct AnswerCitation: Codable, Sendable {
    let momentID: UUID
    let quote: String
}
struct GroundedAnswer: Codable, Sendable {
    let text: String
    let citations: [AnswerCitation]
    var contextLimited = false
}
protocol MomentAnswering: Sendable {
    func answer(question: String, evidence: [Evidence]) async throws -> GroundedAnswer?
}

extension QueryFeature {
    func search(_ question: String, previousQuestions: [String]) async throws -> QueryResult {
        try await search(question)
    }
}
