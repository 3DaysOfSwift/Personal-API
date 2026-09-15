import Foundation
import Observation

/// Owns the feature boundary; each search returns its own result without shared request state.
@MainActor @Observable final class QueryManager: QueryFeature {
  private let worker: QueryWorker

  init(
    repository: any PersonalDataRepository, retriever: MomentRetriever, index: LocalQueryIndex,
    semanticSearch: (any SemanticMomentSearching)? = nil, answerer: (any MomentAnswering)? = nil
  ) {
    worker = QueryWorker(
      repository: repository, retriever: retriever, index: index,
      semanticSearch: semanticSearch, answerer: answerer)
  }

  func canSearch(_ question: String) -> Bool {
    !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && question.count <= 500
  }

  func search(_ question: String) async throws -> QueryResult {
    try await worker.search(question, previousQuestions: [])
  }

  func search(_ question: String, previousQuestions: [String]) async throws -> QueryResult {
    try await worker.search(question, previousQuestions: previousQuestions)
  }
}
