import XCTest

@testable import PersonalAPI

@MainActor final class ThemeManagerTests: XCTestCase {
  func testMissingOrUnknownPreferenceUsesMidnight() {
    let preferences = MemoryPreferences()
    XCTAssertEqual(ThemeManager(preferences: preferences).palette, .midnight)
    preferences.colourThemeID = "Removed theme"
    XCTAssertEqual(ThemeManager(preferences: preferences).palette, .midnight)
  }

  func testEveryThemePersistsAcrossReconstruction() throws {
    let suiteName = "ThemeManagerTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let manager = ThemeManager(preferences: LocalPreferences(defaults: defaults))

    for theme in AppColourTheme.all {
      manager.palette = theme
      let restoredDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
      let restored = ThemeManager(preferences: LocalPreferences(defaults: restoredDefaults))
      XCTAssertEqual(restored.palette, theme)
    }
  }
}
