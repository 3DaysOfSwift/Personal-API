import Foundation
import Observation

@MainActor @Observable final class AnswerFeedbackViewModel {
  private let chats: any ConversationsFeature
  var reason: AnswerFeedback.Rating = .inventedDetail
  var explanation = ""
  private(set) var error: String?
  private(set) var saved = false
  private(set) var isSaving = false
  init(chats: any ConversationsFeature = AppModel.shared.conversationsFeature) {
    self.chats = chats
  }
  func submit(conversationID: UUID, turnID: UUID) {
    guard !isSaving else { return }
    isSaving = true
    Task { await save(conversationID: conversationID, turnID: turnID) }
  }
  func save(conversationID: UUID, turnID: UUID) async {
    defer { isSaving = false }
    do {
      try await chats.recordFeedback(
        reason, explanation: explanation, turnID: turnID, conversationID: conversationID)
      error = nil
      saved = true
    } catch { self.error = error.localizedDescription }
  }
}
