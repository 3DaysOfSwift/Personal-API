import Foundation
import SwiftData

/// All database work runs on this actor, using fresh contexts per transaction.
/// Existing v1 model identities and stored properties are retained.
actor LocalDataStore: PersonalDataRepository {
    private let storeURL: URL?
    private var container: ModelContainer?
    init(storeURL: URL? = nil) { self.storeURL = storeURL }

    private func makeContext() throws -> ModelContext {
        if container == nil {
            let schema = Schema([Moment.self, PersonalFact.self])
            let configuration: ModelConfiguration
            if let storeURL {
                configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            } else {
                configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            }
            container = try ModelContainer(for: schema, configurations: [configuration])
        }
        guard let container else { throw MomentError.missingMoment }
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
    private func snapshot(_ value: Moment) -> MomentSnapshot {
        MomentSnapshot(id: value.id, text: value.text, createdAt: value.createdAt,
                       happenedAt: value.happenedAt, source: value.source,
                       analysisData: value.analysisData, processingState: value.processingState)
    }
    func loadMoments() throws -> [MomentSnapshot] {
        try makeContext().fetch(FetchDescriptor<Moment>()).sorted { $0.createdAt > $1.createdAt }.map(snapshot)
    }
    func saveMoment(_ value: MomentSnapshot) throws {
        let context = try makeContext()
        let record = Moment(text: value.text, happenedAt: value.happenedAt)
        record.id = value.id; record.createdAt = value.createdAt; record.source = value.source
        context.insert(record)
        try context.save()
    }
    func saveAnalysis(_ analysis: MomentAnalysis, momentID: UUID) throws -> MomentSnapshot {
        let context = try makeContext()
        guard let record = try context.fetch(FetchDescriptor<Moment>()).first(where: { $0.id == momentID }) else { throw MomentError.missingMoment }
        record.analysisData = try JSONEncoder().encode(analysis)
        record.processingState = "complete"
        try context.save()
        return snapshot(record)
    }
    func markAnalysesPending() throws -> [MomentSnapshot] {
        let context = try makeContext()
        let records = try context.fetch(FetchDescriptor<Moment>()).sorted { $0.createdAt > $1.createdAt }
        for record in records { record.processingState = "pending" }
        try context.save()
        return records.map(snapshot)
    }
    func loadFacts() throws -> [PersonalFactSnapshot] {
        try makeContext().fetch(FetchDescriptor<PersonalFact>()).sorted { $0.createdAt > $1.createdAt }.map {
            PersonalFactSnapshot(id: $0.id, label: $0.label, value: $0.value, createdAt: $0.createdAt)
        }
    }
    func saveFact(_ value: PersonalFactSnapshot) throws {
        let context = try makeContext()
        let record = PersonalFact(label: value.label, value: value.value)
        record.id = value.id; record.createdAt = value.createdAt
        context.insert(record)
        try context.save()
    }
    func exportArchive() throws -> Data {
        // No suspension between these reads; actor-owned writes cannot interleave.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(PersonalArchive(exportedAt: Date(), moments: loadMoments().map(PersonalArchive.MomentRecord.init), facts: loadFacts()))
    }
}
