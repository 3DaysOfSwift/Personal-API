import SwiftUI

struct AppColourTheme {
  let background: Color
  let surface: Color
  let primary: Color
  let secondary: Color
  let accent: Color
  let interactiveAccent: Color
  let onAccent: Color
  let error: Color
  static let brandPurple = Color(red: 103 / 255.0, green: 80 / 255.0, blue: 184 / 255.0)
  static let activeViolet = Color(red: 161 / 255.0, green: 138 / 255.0, blue: 230 / 255.0)
  static let softWhite = Color(red: 245 / 255.0, green: 243 / 255.0, blue: 248 / 255.0)
  static let coolGrey = Color(red: 165 / 255.0, green: 161 / 255.0, blue: 173 / 255.0)
  static let midnight = AppColourTheme(
    background: .black,
    surface: Color(red: 20 / 255.0, green: 19 / 255.0, blue: 22 / 255.0),
    primary: softWhite, secondary: coolGrey,
    accent: brandPurple, interactiveAccent: activeViolet, onAccent: .white, error: .red)
  static let graphite = AppColourTheme(
    background: Color(white: 0.09), surface: Color(white: 0.16),
    primary: softWhite, secondary: coolGrey,
    accent: brandPurple, interactiveAccent: activeViolet, onAccent: .white, error: .orange)
}

/// Keeps the visible button surface and its tap area at least 40 points tall.
struct PersonalAPIButtonStyle: ButtonStyle {
  enum Appearance { case plain, bordered, filled, outlined }
  var appearance: Appearance = .plain
  var minimumHeight: CGFloat = 40
  @Environment(ThemeManager.self) private var theme
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, appearance == .plain ? 0 : 12)
      .frame(minHeight: minimumHeight)
      .foregroundStyle(
        appearance == .outlined
          ? .white : (appearance == .filled ? theme.theme.onAccent : theme.theme.primary)
      )
      .background(background, in: RoundedRectangle(cornerRadius: 12))
      .overlay {
        if appearance == .outlined {
          RoundedRectangle(cornerRadius: 12).strokeBorder(.white, lineWidth: 1)
        }
      }
      .contentShape(Rectangle())
      .opacity(isEnabled ? (configuration.isPressed ? 0.65 : 1) : 0.4)
  }

  private var background: Color {
    switch appearance {
    case .plain: .clear
    case .bordered: theme.theme.surface
    case .filled: theme.theme.accent
    case .outlined: .black
    }
  }
}
