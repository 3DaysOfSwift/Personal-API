import Foundation

@MainActor final class LocalPreferences: PreferencesRepository {
  private let defaults: UserDefaults
  init(defaults: UserDefaults) { self.defaults = defaults }
  var colourThemeID: String? {
    get { defaults.string(forKey: "colourThemeID") }
    set { defaults.set(newValue, forKey: "colourThemeID") }
  }
  var onboarded: Bool {
    get { defaults.bool(forKey: "onboarded") }
    set { defaults.set(newValue, forKey: "onboarded") }
  }
  var lockEnabled: Bool {
    get { defaults.bool(forKey: "appLockEnabled") }
    set { defaults.set(newValue, forKey: "appLockEnabled") }
  }
}
