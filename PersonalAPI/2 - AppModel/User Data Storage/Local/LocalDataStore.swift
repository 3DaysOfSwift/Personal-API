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
    MomentSnapshot(
      id: value.id, text: value.text, createdAt: value.createdAt,
      happenedAt: value.happenedAt, source: value.source,
      analysisData: value.analysisData, processingState: value.processingState)
  }
  func loadMoments() throws -> [MomentSnapshot] {
    try makeContext().fetch(FetchDescriptor<Moment>()).sorted { $0.createdAt > $1.createdAt }.map(
      snapshot)
  }
  func saveMoment(_ value: MomentSnapshot) throws {
    let context = try makeContext()
    let record = Moment(text: value.text, happenedAt: value.happenedAt)
    record.id = value.id
    record.createdAt = value.createdAt
    record.source = value.source
    context.insert(record)
    try context.save()
  }
  private func removeDerivedFacts(for id: UUID, in context: ModelContext) throws {
    for fact in try context.fetch(FetchDescriptor<PersonalFact>()) {
      if let data = fact.derivationData,
        try JSONDecoder().decode(FactDerivation.self, from: data).momentID == id
      {
        context.delete(fact)
      }
    }
  }
  func updateMoment(_ original: MomentSnapshot, text: String) throws -> MomentSnapshot {
    let context = try makeContext()
    guard
      let record = try context.fetch(FetchDescriptor<Moment>()).first(where: {
        $0.id == original.id
      })
    else { throw MomentError.missingMoment }
    guard record.text == original.text else { throw MomentError.changedMoment }
    record.replaceTextFromUserEdit(text)
    record.analysisData = nil
    record.processingState = "pending"
    try removeDerivedFacts(for: original.id, in: context)
    try context.save()
    return snapshot(record)
  }
  func deleteMoment(_ original: MomentSnapshot) throws {
    let context = try makeContext()
    guard
      let record = try context.fetch(FetchDescriptor<Moment>()).first(where: {
        $0.id == original.id
      })
    else { throw MomentError.missingMoment }
    guard record.text == original.text else { throw MomentError.changedMoment }
    try removeDerivedFacts(for: original.id, in: context)
    context.delete(record)
    try context.save()
  }
  func saveAnalysis(_ analysis: MomentAnalysis, momentID: UUID) throws -> MomentSnapshot {
    let context = try makeContext()
    guard
      let record = try context.fetch(FetchDescriptor<Moment>()).first(where: { $0.id == momentID })
    else { throw MomentError.missingMoment }
    record.analysisData = try JSONEncoder().encode(analysis)
    record.processingState = "complete"
    try context.save()
    return snapshot(record)
  }
  func markAnalysesPending() throws -> [MomentSnapshot] {
    let context = try makeContext()
    let records = try context.fetch(FetchDescriptor<Moment>()).sorted {
      $0.createdAt > $1.createdAt
    }
    for record in records { record.processingState = "pending" }
    try context.save()
    return records.map(snapshot)
  }
  func loadFacts() throws -> [PersonalFactSnapshot] {
    try makeContext().fetch(FetchDescriptor<PersonalFact>()).sorted { $0.createdAt > $1.createdAt }
      .map {
        PersonalFactSnapshot(
          id: $0.id, label: $0.label, value: $0.value, createdAt: $0.createdAt,
          derivation: try $0.derivationData.map {
            try JSONDecoder().decode(FactDerivation.self, from: $0)
          })
      }
  }
  func saveFact(_ value: PersonalFactSnapshot) throws {
    let context = try makeContext()
    let record = PersonalFact(label: value.label, value: value.value)
    record.id = value.id
    record.createdAt = value.createdAt
    record.derivationData = try value.derivation.map { try JSONEncoder().encode($0) }
    context.insert(record)
    try context.save()
  }
  func replaceDerivedFacts(_ facts: [PersonalFactSnapshot], source: MomentSnapshot) throws {
    let context = try makeContext()
    guard
      let current = try context.fetch(FetchDescriptor<Moment>()).first(where: { $0.id == source.id }
      ),
      current.text == source.text, facts.allSatisfy({ $0.isSupported(by: source) })
    else {
      throw MomentError.missingMoment
    }
    let records = try context.fetch(FetchDescriptor<PersonalFact>())
    let existing = try records.filter { record in
      guard let data = record.derivationData else { return false }
      return try JSONDecoder().decode(FactDerivation.self, from: data).momentID == source.id
    }
    if existing.count == facts.count
      && existing.allSatisfy({ record in
        facts.contains { fact in
          record.label == fact.label && record.value == fact.value
            && (record.derivationData.flatMap {
              try? JSONDecoder().decode(FactDerivation.self, from: $0)
            }) == fact.derivation
        }
      })
    {
      return
    }
    for record in existing {
      if let data = record.derivationData,
        try JSONDecoder().decode(FactDerivation.self, from: data).momentID == source.id
      {
        context.delete(record)
      }
    }
    for fact in facts {
      let record = PersonalFact(label: fact.label, value: fact.value)
      record.id = fact.id
      record.createdAt = fact.createdAt
      record.derivationData = try fact.derivation.map { try JSONEncoder().encode($0) }
      context.insert(record)
    }
    // One transaction: readers never see a partially replaced extraction.
    try context.save()
  }
  func exportArchive() throws -> Data {
    // No suspension between these reads; actor-owned writes cannot interleave.
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(
      PersonalArchive(
        exportedAt: Date(), moments: loadMoments().map(PersonalArchive.MomentRecord.init),
        facts: loadFacts()))
  }
}
