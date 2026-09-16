import Observation
import SwiftUI

@MainActor @Observable final class ThemeManager {
  var palette: AppColourTheme {
    didSet { preferences.colourThemeID = theme.id }
  }

  private let preferences: any PreferencesRepository

  init(preferences: any PreferencesRepository) {
    self.preferences = preferences
    palette = AppColourTheme.all.first { $0.id == preferences.colourThemeID } ?? .midnight
  }
}
