import Foundation
struct Evidence: Identifiable, Sendable {
    let moment: MomentSnapshot
    let score: Int
    var id: UUID { moment.id }
}
enum RetrievalOutcome: Sendable { case noEvidence, matches }
struct QueryResult: Sendable {
    var outcome: RetrievalOutcome { evidence.isEmpty ? .noEvidence : .matches }
    let evidence: [Evidence]
    let searchedCount: Int
    var method: SearchMethod = .keywords(reason: nil)
}
@MainActor protocol QueryFeature: AnyObject, Sendable {
    func canSearch(_ question: String) -> Bool
    func search(_ question: String) async throws -> QueryResult
}

enum SearchMethod: Sendable, Equatable {
    case onDeviceAI
    case keywords(reason: String?)
}
