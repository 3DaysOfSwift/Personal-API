import XCTest

@testable import PersonalAPI

@MainActor final class AppModelTests: XCTestCase {
  func testRepeatedLaunchSharesInitialLoad() async {
    let graph = TestAppModelFactory()
    graph.app.applicationDidFinishLaunching()
    graph.app.applicationDidFinishLaunching()
    await graph.app.awaitInitialLoads()
    let calls = await graph.repository.momentLoads
    XCTAssertEqual(calls, 1)
  }
}
