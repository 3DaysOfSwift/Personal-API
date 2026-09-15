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
    var feedback: String?
    private let query: any QueryFeature
    private var requestID = UUID()
    private var searchTask: Task<Void, Never>?
    init(query: any QueryFeature = AppModel.shared.queryFeature) { self.query = query }
    var canSearch: Bool { query.canSearch(question) }
    func submitSearch() {
        searchTask?.cancel()
        searchTask = Task { await search() }
    }
    func cancelSearch() {
        requestID = UUID()
        searchTask?.cancel(); searchTask = nil; isSearching = false
    }
    func search() async {
        let id = UUID(); requestID = id
        submitted = question; feedback = nil; error = nil
        results = []; searched = false; isSearching = true
        defer { if requestID == id { isSearching = false } }
        do {
            let result = try await query.search(submitted)
            guard requestID == id, !Task.isCancelled else { return }
            results = result.evidence; searchedCount = result.searchedCount; searched = true
            switch result.outcome {
            case .noEvidence: answer = "I don’t know enough about you yet. No Moments matched these keywords. Try words from your original entry."
            case .matches: answer = "I found \(results.count) matching Moments. Read the original words below to judge whether they answer your question."
            }
        } catch is CancellationError { }
        catch { if requestID == id { self.error = error.localizedDescription } }
    }
}
