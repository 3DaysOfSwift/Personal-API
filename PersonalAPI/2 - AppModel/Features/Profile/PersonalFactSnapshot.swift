import Foundation
struct PersonalFactSnapshot: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    let label: String
    let value: String
    let createdAt: Date
    var derivation: FactDerivation? = nil
}

enum ProfileError: LocalizedError {
    case emptyFact
    var errorDescription: String? { "Add both a label and a value." }
}

/// Nil on legacy manually entered facts; these are not eligible for journal search.
struct FactDerivation: Sendable, Codable, Equatable {
    let momentID: UUID
    let sourceText: String
    let extractorVersion: String
}

extension PersonalFactSnapshot {
    func isSupported(by moment: MomentSnapshot) -> Bool {
        guard let derivation else { return false }
        return derivation.momentID == moment.id && derivation.sourceText == moment.text
            && derivation.extractorVersion == LocalJournalFactExtractor.version
            && !value.isEmpty && moment.text.contains(value)
    }
}
