import Foundation
import Observation

@MainActor @Observable final class EditJournalEntryViewModel {
    private let moments: any MomentsFeature
    private var original: MomentSnapshot?
    var text = ""
    private(set) var isWorking = false
    private(set) var error: String?
    init(moments: any MomentsFeature = AppModel.shared.momentsFeature) { self.moments = moments }
    var hasChanges: Bool { original.map { $0.text != text } ?? false }
    var canSave: Bool { !isWorking && hasChanges && moments.canRecord(text) }
    func prepare(_ entry: MomentSnapshot) {
        guard original == nil else { return }
        original = entry; text = entry.text
    }
    func save() async -> Bool {
        guard canSave, let original else { return false }
        isWorking = true; defer { isWorking = false }
        do { try await moments.updateMoment(original, text: text); error = nil; return true }
        catch { self.error = error.localizedDescription; return false }
    }
    func delete() async -> Bool {
        guard !isWorking, let original else { return false }
        isWorking = true; defer { isWorking = false }
        do { try await moments.deleteMoment(original); error = nil; return true }
        catch { self.error = error.localizedDescription; return false }
    }
}
