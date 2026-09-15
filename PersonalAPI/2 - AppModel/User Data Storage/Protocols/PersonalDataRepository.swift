import Foundation

protocol PersonalDataRepository: Sendable {
    func loadMoments() async throws -> [MomentSnapshot]
    func saveMoment(_ moment: MomentSnapshot) async throws
    func saveAnalysis(_ analysis: MomentAnalysis, momentID: UUID) async throws -> MomentSnapshot
    func markAnalysesPending() async throws -> [MomentSnapshot]
    func loadFacts() async throws -> [PersonalFactSnapshot]
    func saveFact(_ fact: PersonalFactSnapshot) async throws
    func exportArchive() async throws -> Data
}

