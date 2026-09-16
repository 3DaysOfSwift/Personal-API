import Foundation

@MainActor protocol PreferencesRepository: AnyObject {
  var colourThemeID: String? { get set }
  var onboarded: Bool { get set }
  var lockEnabled: Bool { get set }
}
