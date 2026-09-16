import SwiftUI

@MainActor final class ApplicationDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    #if DEBUG
      if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
        return true
      }
    #endif
    AppModel.shared.applicationDidFinishLaunching()
    return true
  }
}

@main struct PersonalAPIApp: App {
  @UIApplicationDelegateAdaptor(ApplicationDelegate.self) private var delegate
  @State private var theme = ThemeManager(preferences: LocalPreferences(defaults: .standard))
  var body: some Scene {
    WindowGroup {
      Group {
        #if DEBUG
          if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            RootView()
          } else {
            Color.clear
          }
        #else
          RootView()
        #endif
      }
      .environment(theme)
      .buttonStyle(PersonalAPIButtonStyle())
      .preferredColorScheme(.dark)
      .tint(theme.palette.interactiveAccent)
      .foregroundStyle(theme.palette.primary)
    }
  }
}
