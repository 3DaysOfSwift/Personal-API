import SwiftUI

@MainActor final class ApplicationDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
      AppModel.shared.applicationDidFinishLaunching()
    }
    return true
  }
}

@main struct PersonalAPIApp: App {
  @UIApplicationDelegateAdaptor(ApplicationDelegate.self) private var delegate
  @State private var theme = ThemeManager()
  var body: some Scene {
    WindowGroup {
      Group {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
          RootView()
        } else {
          Color.clear
        }
      }
      .environment(theme)
      .buttonStyle(PersonalAPIButtonStyle())
      .preferredColorScheme(.dark)
      .tint(theme.theme.interactiveAccent)
      .foregroundStyle(theme.theme.primary)
    }
  }
}
