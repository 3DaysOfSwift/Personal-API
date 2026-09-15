import Foundation
import Observation

@MainActor @Observable final class QueryViewModel {
    var question = ""
    private(set) var conversationID = UUID()
    private(set) var error: String?
    private(set) var isSubmitting = false
    private(set) var loaded = false
    private let chats: any ConversationsFeature
    private var task: Task<Void, Never>?
    init(chats: any ConversationsFeature = AppModel.shared.conversationsFeature) { self.chats = chats }
    var conversations: [Conversation] { chats.conversations }
    var turns: [ChatTurn] { conversations.first { $0.id == conversationID }?.turns ?? [] }
    var isBusy: Bool { isSubmitting || chats.isBusy }
    var activeTurnID: UUID? { chats.activeTurnID }
    var canSearch: Bool { !isSubmitting && chats.canSend(question) }
    func load() async {
        do {
            try await chats.load()
            if !loaded, let latest = conversations.first { conversationID = latest.id }
            loaded = true; error = nil
        } catch { self.error = error.localizedDescription }
    }
    func submitSearch() {
        guard canSearch else { return }
        isSubmitting = true
        task = Task { await sendDraft() }
    }
    func sendDraft() async {
        let draft = question
        let id = conversationID
        let originalCount = turns.count
        question = ""
        isSubmitting = true
        defer { isSubmitting = false }
        error = nil
        do {
            try await chats.send(draft, in: id)
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
        if turns.count == originalCount && question.isEmpty { question = draft }
    }
    func answerAgain() {
        guard !isBusy else { return }
        isSubmitting = true
        task = Task {
            defer { isSubmitting = false }
            do { error = nil; try await chats.answerAgain(in: conversationID) }
            catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }
    func cancelSearch() { task?.cancel() }
    func newChat() {
        guard !isBusy else { return }
        conversationID = UUID(); question = ""; error = nil
    }
    func open(_ id: UUID) {
        guard !isBusy else { return }
        conversationID = id; question = ""; error = nil
    }
    func delete(_ id: UUID) async {
        do {
            try await chats.delete(id)
            if conversationID == id { newChat() }
        } catch { self.error = error.localizedDescription }
    }
    @discardableResult
    func feedback(_ rating: AnswerFeedback.Rating, explanation: String, turnID: UUID) async -> Bool {
        do {
            try await chats.recordFeedback(rating, explanation: explanation, turnID: turnID, conversationID: conversationID)
            error = nil
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func exportFailed(_ failure: Error) { error = failure.localizedDescription }
    func exportChats() async -> Data? {
        do { return try await chats.export() }
        catch { self.error = error.localizedDescription; return nil }
    }
    func answer(for turn: ChatTurn) -> String {
        if let failure = turn.failure { return failure }
        guard let result = turn.result else { return "This answer was interrupted. Tap Answer again to continue." }
        if let answer = result.generatedAnswer { return answer.text }
        if let issue = result.answerIssue { return issue }
        switch result.method {
        case .keywords(let reason): return reason ?? "On-device answering is unavailable for this question."
        case .onDeviceAI: return "I don’t have enough information in your recorded memories to answer that yet."
        }
    }
}
