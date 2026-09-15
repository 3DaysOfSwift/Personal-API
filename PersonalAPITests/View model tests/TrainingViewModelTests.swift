import XCTest
@testable import PersonalAPI
@MainActor final class TrainingViewModelTests: XCTestCase {
    func testSavePreservesSourceAndClearsDraft() async throws {
        let graph = TestAppModelFactory()
        let vm = TrainingViewModel(moments: graph.app.momentsFeature)
        let original = "  Dad called.\nCafé 🌱\n"
        vm.text = original
        await vm.save()
        XCTAssertEqual(vm.text, "")
        XCTAssertEqual(vm.moments.first?.text, original)
        await graph.app.momentsFeature.enrichPendingMoments()
        XCTAssertEqual(vm.moments.first?.text, original)
        XCTAssertEqual(vm.moments.first?.analysis?.title, "  Dad called.")
    }
    func testSaveFailureKeepsDraftAndDoesNotPublish() async {
        let graph = TestAppModelFactory()
        await graph.repository.setFailure(true)
        let vm = TrainingViewModel(moments: graph.app.momentsFeature)
        vm.text = "Keep this thought"
        await vm.save()
        XCTAssertEqual(vm.text, "Keep this thought")
        XCTAssertTrue(vm.moments.isEmpty)
        XCTAssertNotNil(vm.error)
    }
    func testWhitespaceIsRejected() async {
        let graph = TestAppModelFactory()
        let vm = TrainingViewModel(moments: graph.app.momentsFeature)
        vm.text = " \n "
        XCTAssertFalse(vm.canSave)
        await vm.save()
        XCTAssertTrue(vm.moments.isEmpty)
        XCTAssertNotNil(vm.error)
    }
}
