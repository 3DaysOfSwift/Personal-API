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
