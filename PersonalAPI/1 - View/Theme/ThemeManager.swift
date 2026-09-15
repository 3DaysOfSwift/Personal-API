import Observation
import SwiftUI

@MainActor @Observable final class ThemeManager {
  var theme: AppColourTheme = .midnight
}
