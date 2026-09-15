import Foundation
import Observation
@MainActor @Observable final class MomentDetailViewModel {
    private let moments: any MomentsFeature
    init(moments: any MomentsFeature = AppModel.shared.momentsFeature) { self.moments = moments }
    func current(_ snapshot: MomentSnapshot) -> MomentSnapshot {
        moments.currentMoment(snapshot)
    }
}
