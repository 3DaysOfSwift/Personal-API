import Foundation
import Observation
@MainActor @Observable final class ProfileViewModel {
    var label = ""
    var value = ""
    private(set) var error: String?
    private(set) var isSaving = false
    private let profile: any ProfileFeature
    init(profile: any ProfileFeature = AppModel.shared.profileFeature) { self.profile = profile }
    var facts: [PersonalFactSnapshot] { profile.facts }
    var canSave: Bool { !isSaving && profile.canSave(label: label, value: value) }
    var loadError: String? { profile.loadError }
    var isLoading: Bool { profile.isLoading }
    func load() async { await profile.loadIfRequired() }
    func retry() async { await profile.refresh() }
    func save() async {
        guard !isSaving else { return }
        isSaving = true; defer { isSaving = false }
        do { try await profile.addFact(label: label, value: value); label = ""; value = ""; error = nil }
        catch { self.error = error.localizedDescription }
    }
}
