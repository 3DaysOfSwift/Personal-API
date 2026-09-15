import Foundation

/// Separate, versioned chat archive. Never writes the canonical journal database.
actor LocalConversationStore: ConversationRepository {
    private let url: URL
    private struct Archive: Codable {
        var version = 1
        let conversations: [Conversation]
    }
    init(url: URL) { self.url = url }
    func load() throws -> [Conversation] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: url))
        guard archive.version == 1 else { throw ConversationError.unsupportedArchive }
        return archive.conversations
    }
    func save(_ conversations: [Conversation]) throws {
        let data = try export(conversations)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
    func export(_ conversations: [Conversation]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Archive(conversations: conversations))
    }
}
