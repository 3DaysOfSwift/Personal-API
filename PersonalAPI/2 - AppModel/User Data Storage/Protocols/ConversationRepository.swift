import Foundation
protocol ConversationRepository: Sendable {
    func load() async throws -> [Conversation]
    func save(_ conversations: [Conversation]) async throws
    func export(_ conversations: [Conversation]) async throws -> Data
}
