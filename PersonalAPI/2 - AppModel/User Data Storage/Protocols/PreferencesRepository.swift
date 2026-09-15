import Foundation
@MainActor protocol PreferencesRepository: AnyObject {
    var onboarded: Bool { get set }
    var lockEnabled: Bool { get set }
}
