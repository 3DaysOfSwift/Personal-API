import SwiftUI
import Observation
@MainActor @Observable final class ThemeManager {
    var theme: AppColourTheme = .midnight
}
