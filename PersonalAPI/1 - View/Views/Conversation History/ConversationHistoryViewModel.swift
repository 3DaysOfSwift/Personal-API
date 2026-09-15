import Foundation
import Observation

@MainActor @Observable final class ConversationHistoryViewModel {
  private let chats: any ConversationsFeature
  var pendingDeletion: UUID?
  private(set) var error: String?
  init(chats: any ConversationsFeature = AppModel.shared.conversationsFeature) {
    self.chats = chats
  }
  var conversations: [Conversation] { chats.conversations }
  var isBusy: Bool { chats.isBusy }
  func load() async {
    do {
      try await chats.load()
      error = nil
    } catch { self.error = error.localizedDescription }
  }
  func deletePending() {
    guard let id = pendingDeletion else { return }
    pendingDeletion = nil
    Task {
      do {
        try await chats.delete(id)
        error = nil
      } catch { self.error = error.localizedDescription }
    }
  }
}
