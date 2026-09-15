import XCTest
@testable import PersonalAPI
@MainActor final class AuthenticationManagerTests: XCTestCase {
    func testLateSuccessAfterBackgroundCannotUnlock() async {
        let graph = TestAppModelFactory()
        graph.preferences.lockEnabled = true
        graph.app.authenticationFeature.loadPreference()
        graph.authentication.suspended = true
        let request = Task { await graph.app.authenticationFeature.unlock() }
        while graph.authentication.pending == nil { await Task.yield() }
        graph.app.authenticationFeature.lockForBackground()
        graph.authentication.complete()
        await request.value
        XCTAssertFalse(graph.app.authenticationFeature.unlocked)
        XCTAssertTrue(graph.app.authenticationFeature.enabled)
    }
    func testDisablingRequiresAuthentication() async {
        let graph = TestAppModelFactory()
        graph.preferences.lockEnabled = true
        graph.app.authenticationFeature.loadPreference()
        graph.authentication.success = false
        await graph.app.authenticationFeature.setEnabled(false)
        XCTAssertTrue(graph.app.authenticationFeature.enabled)
        XCTAssertTrue(graph.preferences.lockEnabled)
    }
}
