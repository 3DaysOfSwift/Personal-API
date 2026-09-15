import Foundation
import Observation
@MainActor @Observable final class TrainingViewModel {
    var text = ""
    var hasEventDate = false
    var eventDate = Date()
    private(set) var error: String?
    private(set) var didSave = false
    private(set) var isSaving = false
    private let momentsFeature: any MomentsFeature
    init(moments: any MomentsFeature = AppModel.shared.momentsFeature) { momentsFeature = moments }
    var moments: [MomentSnapshot] { momentsFeature.moments }
    var canSave: Bool { !isSaving && momentsFeature.canRecord(text) }
    var loadError: String? { momentsFeature.loadError }
    var enrichmentError: String? { momentsFeature.enrichmentError }
    var isLoading: Bool { momentsFeature.isLoading }
    func load() async { await momentsFeature.loadIfRequired() }
    func retry() async { await momentsFeature.refresh() }
    func save() async {
        guard !isSaving else { return }
        didSave = false
        isSaving = true; defer { isSaving = false }
        do {
            try await momentsFeature.recordMoment(text: text, happenedAt: hasEventDate ? eventDate : nil)
            text = ""; hasEventDate = false; error = nil; didSave = true
        } catch { self.error = "Your draft is still here. \(error.localizedDescription)" }
    }
}
