import XCTest
@testable import PersonalAPI
final class LocalDataStoreTests: XCTestCase {
    func testReopenAndExportPreserveSourceAndTimestamp() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("test.store")
        let source = MomentSnapshot(id: UUID(), text: "  café 🌱\n", createdAt: Date(timeIntervalSince1970: 123.456), happenedAt: nil, source: "manual", analysisData: nil, processingState: "pending")
        let store = LocalDataStore(storeURL: url)
        try await store.saveMoment(source)
        let reopened = LocalDataStore(storeURL: url)
        let records = try await reopened.loadMoments()
        XCTAssertEqual(records.first, source)
        let data = try await reopened.exportArchive()
        let archive = try JSONDecoder().decode(PersonalArchive.self, from: data)
        XCTAssertEqual(archive.moments.first?.text, source.text)
        XCTAssertEqual(archive.moments.first?.id, source.id)
        XCTAssertEqual(archive.moments.first?.createdAt, source.createdAt)
    }
    func testProcessorDoesNotInventSensitiveMetadata() async throws {
        let processor = LocalMomentProcessor(now: { Date(timeIntervalSince1970: 100) })
        let result = try await processor.analyse(MomentInput(text: "Dad called yesterday", createdAt: Date()))
        XCTAssertTrue(result.emotions.isEmpty)
        XCTAssertNil(result.extractedEventDate)
        XCTAssertNil(result.lifeEvent)
    }
}

extension LocalDataStoreTests {
    func testDerivedFactsReopenExportAndReplaceWithoutDuplicatesOrLosingLegacyFacts() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("facts.store")
        let store = LocalDataStore(storeURL: url)
        let source = MomentSnapshot(id: UUID(), text: "I enjoyed teaching in 2012, but no longer do.",
            createdAt: Date(), happenedAt: nil, source: "manual", analysisData: nil, processingState: "pending")
        try await store.saveMoment(source)
        let legacy = PersonalFactSnapshot(id: UUID(), label: "Old fact", value: "Keep me", createdAt: Date())
        try await store.saveFact(legacy)
        let extractor = LocalJournalFactExtractor(now: { Date() })
        let facts = try await extractor.extract(from: source)
        try await store.replaceDerivedFacts(facts, source: source)
        try await store.replaceDerivedFacts(extractor.extract(from: source), source: source)
        let reopened = LocalDataStore(storeURL: url)
        let loaded = try await reopened.loadFacts()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains(legacy))
        XCTAssertEqual(loaded.first(where: { $0.derivation != nil }), facts.first)
        let archive = try JSONDecoder().decode(PersonalArchive.self, from: await reopened.exportArchive())
        XCTAssertTrue(archive.facts.contains(facts[0]))
        try await reopened.replaceDerivedFacts([], source: source)
        let remaining = try await reopened.loadFacts()
        XCTAssertEqual(remaining, [legacy])
        let sources = try await reopened.loadMoments()
        XCTAssertEqual(sources.first?.text, source.text)
    }
}

extension LocalDataStoreTests {
    func testLegacyFactJSONDecodesWithoutDerivation() throws {
        let id = UUID()
        let data = try JSONSerialization.data(withJSONObject: ["id": id.uuidString,
            "label": "Occupation", "value": "Teacher", "createdAt": 0])
        let legacy = try JSONDecoder().decode(PersonalFactSnapshot.self, from: data)
        XCTAssertEqual(legacy.id, id)
        XCTAssertEqual(legacy.value, "Teacher")
        XCTAssertNil(legacy.derivation)
    }

    func testInvalidReplacementLeavesExistingDerivedFactsIntact() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalDataStore(storeURL: folder.appendingPathComponent("facts.store"))
        let source = MomentSnapshot(id: UUID(), text: "My job is teaching.", createdAt: Date(),
            happenedAt: nil, source: "manual", analysisData: nil, processingState: "pending")
        try await store.saveMoment(source)
        let facts = try await LocalJournalFactExtractor(now: { Date() }).extract(from: source)
        try await store.replaceDerivedFacts(facts, source: source)
        let invented = PersonalFactSnapshot(id: UUID(), label: "Occupation", value: "I work as a pilot.",
            createdAt: Date(), derivation: facts.first?.derivation)
        do {
            try await store.replaceDerivedFacts([invented], source: source)
            XCTFail("Unsupported replacement should fail")
        } catch { }
        let loaded = try await store.loadFacts()
        XCTAssertEqual(loaded, facts)
    }
}
