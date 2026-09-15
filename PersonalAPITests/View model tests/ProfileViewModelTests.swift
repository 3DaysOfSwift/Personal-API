import XCTest
@testable import PersonalAPI
@MainActor final class ProfileViewModelTests: XCTestCase {
    func testFailureRetainsFactAndRetrySavesIt() async {
        let graph = TestAppModelFactory()
        let vm = ProfileViewModel(profile: graph.app.profileFeature)
        vm.label = "Birthplace"; vm.value = "London"
        await graph.repository.setFailure(true)
        await vm.save()
        XCTAssertEqual(vm.value, "London")
        XCTAssertNotNil(vm.error)
        await graph.repository.setFailure(false)
        await vm.save()
        XCTAssertEqual(vm.value, "")
        XCTAssertEqual(vm.facts.first?.value, "London")
    }
}
