import Foundation
struct PersonalFactSnapshot: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    let label: String
    let value: String
    let createdAt: Date
}

enum ProfileError: LocalizedError {
    case emptyFact
    var errorDescription: String? { "Add both a label and a value." }
}
