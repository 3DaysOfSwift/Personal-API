import Foundation
import Observation

@MainActor @Observable final class JournalEntriesViewModel {
    private let moments: any MomentsFeature
    init(moments: any MomentsFeature = AppModel.shared.momentsFeature) { self.moments = moments }
    var entries: [MomentSnapshot] { moments.moments }
    var isLoading: Bool { moments.isLoading }
    var error: String? { moments.loadError }
    func refresh() async { await moments.refresh() }
}
