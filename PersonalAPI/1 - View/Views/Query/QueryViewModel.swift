import Foundation
import Observation
@MainActor @Observable final class QueryViewModel {
    var question = ""
    private(set) var submitted = ""
    private(set) var results: [Evidence] = []
    private(set) var searchedCount = 0
    private(set) var searched = false
    private(set) var isSearching = false
    private(set) var error: String?
    private(set) var answer = ""
    private(set) var hasAIAnswer = false
    private(set) var answerNote: String?
    private(set) var citations: [AnswerCitation] = []
    private(set) var searchMethod = ""
    var feedback: String?
    private let query: any QueryFeature
    private var requestID = UUID()
    private var searchTask: Task<Void, Never>?
    init(query: any QueryFeature = AppModel.shared.queryFeature) { self.query = query }
    var canSearch: Bool { query.canSearch(question) }
    func submitSearch() {
        guard !(isSearching && question == submitted) else { return }
        searchTask?.cancel()
        searchTask = Task { await search() }
    }
    func retryAnswer() { question = submitted; submitSearch() }
    func cancelSearch() {
        requestID = UUID()
        searchTask?.cancel(); searchTask = nil; isSearching = false
    }
    func search() async {
        let id = UUID(); requestID = id
        submitted = question; feedback = nil; error = nil
        results = []; answer = ""; hasAIAnswer = false; answerNote = nil; citations = []; searchMethod = ""; searched = false; isSearching = true
        defer { if requestID == id { isSearching = false } }
        do {
            let result = try await query.search(submitted)
            guard requestID == id, !Task.isCancelled else { return }
            results = result.evidence; searchedCount = result.searchedCount; searched = true
            switch result.method {
            case .onDeviceAI:
                searchMethod = "On-device AI · searched by meaning"
            case .keywords(let reason):
                searchMethod = "Keyword search" + (reason.map { " · " + $0 } ?? "")
            }
            if let generated = result.generatedAnswer {
                answer = generated.text
                hasAIAnswer = true
                citations = generated.citations
                searchMethod = "On-device AI · answered from your Moments"
                answerNote = generated.contextLimited ? "This answer used excerpts from the retrieved Moments. Some text was outside the answer context; inspect the originals for more detail." : nil
            } else {
                if let issue = result.answerIssue {
                    answer = issue
                } else {
                    switch result.method {
                    case .keywords(let reason):
                        answer = reason ?? "I couldn’t generate an AI answer. On-device answering is unavailable for this search."
                    case .onDeviceAI:
                        answer = result.evidence.isEmpty
                            ? "I don’t have enough information in your recorded memories to answer that yet."
                            : "I couldn’t generate an answer from your memories. Please retry."
                    }
                }
            }
        } catch is CancellationError { }
        catch { if requestID == id { self.error = error.localizedDescription } }
    }
}
