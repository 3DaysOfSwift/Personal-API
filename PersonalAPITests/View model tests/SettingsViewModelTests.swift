import XCTest
@testable import PersonalAPI
@MainActor final class SettingsViewModelTests: XCTestCase {
    func testExportFailureCannotPresentOldDocument() async throws {
        let graph = TestAppModelFactory()
        let vm = SettingsViewModel(settings: graph.app.settingsFeature, authentication: graph.app.authenticationFeature)
        let first = await vm.prepareExport()
        XCTAssertTrue(first); XCTAssertNotNil(vm.document)
        await graph.repository.setFailure(true)
        let second = await vm.prepareExport()
        XCTAssertFalse(second); XCTAssertNil(vm.document); XCTAssertNotNil(vm.message)
    }
    func testExportIncludesRawSourceAndFacts() async throws {
        let graph = TestAppModelFactory()
        try await graph.app.momentsFeature.recordMoment(text: "  café\n", happenedAt: nil)
        try await graph.app.profileFeature.addFact(label: "Name", value: "Matthew")
        let vm = SettingsViewModel(settings: graph.app.settingsFeature, authentication: graph.app.authenticationFeature)
        let ready = await vm.prepareExport()
        XCTAssertTrue(ready)
        let document = try XCTUnwrap(vm.document)
        let decoded = try JSONDecoder().decode(PersonalArchive.self, from: document.data)
        XCTAssertEqual(decoded.moments.first?.text, "  café\n")
        XCTAssertEqual(decoded.facts.first?.value, "Matthew")
        XCTAssertEqual(vm.momentCount, 1)
        await graph.app.momentsFeature.enrichPendingMoments()
    }
}
