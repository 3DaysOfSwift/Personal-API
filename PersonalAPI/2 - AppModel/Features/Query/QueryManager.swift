import Foundation

@MainActor final class QueryManager: QueryFeature {
    private let repository: any PersonalDataRepository
    private let retriever: MomentRetriever
    init(repository: any PersonalDataRepository, retriever: MomentRetriever) { self.repository = repository; self.retriever = retriever }
    func canSearch(_ question: String) -> Bool { !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func search(_ question: String) async throws -> QueryResult {
        try Task.checkCancellation()
        let moments = try await repository.loadMoments()
        return try await retriever.search(question, moments: moments)
    }
}

actor MomentRetriever {
    func search(_ question: String, moments: [MomentSnapshot]) throws -> QueryResult {
        let stop: Set<String> = ["what", "when", "where", "have", "had", "did", "the", "and", "about", "my", "me", "i", "a", "an", "of", "to", "do", "is", "was", "are", "you", "some"]
        func tokens(_ text: String) -> Set<String> {
            Set(text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        }
        let terms = tokens(question).subtracting(stop)
        var evidence: [Evidence] = []
        for moment in moments {
            try Task.checkCancellation()
            let score = terms.intersection(tokens(moment.text)).count
            if score > 0 { evidence.append(Evidence(moment: moment, score: score)) }
        }
        let results = evidence.sorted {
            $0.score == $1.score ? $0.moment.createdAt > $1.moment.createdAt : $0.score > $1.score
        }
        return QueryResult(evidence: Array(results.prefix(20)), searchedCount: moments.count)
    }
}
