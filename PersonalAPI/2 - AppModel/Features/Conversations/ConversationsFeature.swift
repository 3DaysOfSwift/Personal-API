import Foundation

struct ChatTurn: Identifiable, Codable, Sendable {
  let id: UUID
  let question: String
  let createdAt: Date
  var result: QueryResult?
  var failure: String?
  var feedback: AnswerFeedback?
}
struct AnswerFeedback: Codable, Sendable {
  enum Rating: String, Codable, CaseIterable {
    case useful, inventedDetail, misunderstood, missingInformation
  }
  let rating: Rating
  let explanation: String
  let recordedAt: Date
}
struct Conversation: Identifiable, Codable, Sendable {
  let id: UUID
  let createdAt: Date
  var updatedAt: Date
  var turns: [ChatTurn]
  var title: String { turns.first.map { String($0.question.prefix(70)) } ?? "New chat" }
}
@MainActor protocol ConversationsFeature: AnyObject {
  var conversations: [Conversation] { get }
  var isBusy: Bool { get }
  var activeTurnID: UUID? { get }
  func load() async throws
  func canSend(_ question: String) -> Bool
  func send(_ question: String, in conversationID: UUID) async throws
  func answerAgain(in conversationID: UUID) async throws
  func delete(_ conversationID: UUID) async throws
  func recordFeedback(
    _ rating: AnswerFeedback.Rating, explanation: String, turnID: UUID, conversationID: UUID)
    async throws
  func export() async throws -> Data
}
enum ConversationError: LocalizedError {
  case busy, missing, unsupportedArchive
  var errorDescription: String? {
    switch self {
    case .busy: return "Please wait for the current operation to finish."
    case .missing: return "This conversation is no longer available."
    case .unsupportedArchive: return "This conversation archive needs a newer app version."
    }
  }
}
