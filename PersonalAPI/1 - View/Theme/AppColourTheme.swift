import SwiftUI
struct AppColourTheme {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let onAccent: Color
    let error: Color
    static let midnight = AppColourTheme(background: .black, surface: .white.opacity(0.07), primary: .white, secondary: .gray, accent: .white, onAccent: .black, error: .red)
    static let graphite = AppColourTheme(background: Color(white: 0.09), surface: Color(white: 0.16), primary: .white, secondary: Color(white: 0.65), accent: .mint, onAccent: .black, error: .orange)
}
