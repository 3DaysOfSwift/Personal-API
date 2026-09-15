import Foundation
import Observation
@MainActor @Observable final class SettingsManager: SettingsFeature {
    private(set) var onboarded = false
    private let preferences: any PreferencesRepository
    private let repository: any PersonalDataRepository
    private let moments: any MomentsFeature
    private let profile: any ProfileFeature
    init(preferences: any PreferencesRepository, repository: any PersonalDataRepository, moments: any MomentsFeature, profile: any ProfileFeature) {
        self.preferences = preferences; self.repository = repository; self.moments = moments; self.profile = profile
    }
    var momentCount: Int { moments.moments.count }
    var factCount: Int { profile.facts.count }
    var enrichmentError: String? { moments.enrichmentError }
    func loadPreference() { onboarded = preferences.onboarded }
    func completeOnboarding() { preferences.onboarded = true; onboarded = true }
    func exportDataset() async throws -> Data { try await repository.exportArchive() }
    func regenerateMetadata() async throws { try await moments.regenerateMetadata() }
}
