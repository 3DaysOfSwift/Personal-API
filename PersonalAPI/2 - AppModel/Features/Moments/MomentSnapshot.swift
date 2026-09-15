import Foundation

/// Immutable source values cross the repository boundary; SwiftData objects never do.
struct MomentSnapshot: Identifiable, Sendable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    let happenedAt: Date?
    let source: String
    var analysisData: Data?
    var processingState: String
    var analysis: MomentAnalysis? {
        guard let analysisData else { return nil }
        do { return try JSONDecoder().decode(MomentAnalysis.self, from: analysisData) }
        catch { return nil } // Preserve readable raw evidence even if regenerable metadata is corrupt.
    }
    var analysisIssue: String? {
        analysisData != nil && analysis == nil ? "Metadata could not be read. Regenerate it in Settings; your original text is safe." : nil
    }
}

struct MomentAnalysis: Codable, Sendable, Equatable {
    var title: String
    var factualTags: [String] = []
    var categories: [String] = []
    var themes: [String] = []
    var emotions: [String] = []
    var significance: String? = nil
    var lifeEvent: String? = nil
    var extractedEventDate: Date? = nil
    var eventDateEvidence: String? = nil
    var processor: String
    var version: Int = 1
    var processedAt: Date
}

struct MomentInput: Sendable {
    let text: String
    let createdAt: Date
}

enum MomentError: LocalizedError {
    case emptyMoment, missingMoment
    var errorDescription: String? {
        switch self {
        case .emptyMoment: return "Write something before saving your Moment."
        case .missingMoment: return "The original Moment could not be found."
        }
    }
}
