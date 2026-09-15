import XCTest
@testable import PersonalAPI
@MainActor final class RootViewModelTests: XCTestCase {
    func testBackgroundRequiresUnlockAgain() async {
        let graph = TestAppModelFactory()
        let vm = RootViewModel(settings: graph.app.settingsFeature, authentication: graph.app.authenticationFeature)
        await graph.app.authenticationFeature.setEnabled(true)
        XCTAssertFalse(vm.requiresUnlock)
        vm.enteredBackground()
        XCTAssertTrue(vm.requiresUnlock)
    }
}
