import Foundation
import Observation

@MainActor @Observable final class MomentDetailViewModel {
  private let moments: any MomentsFeature
  init(moments: any MomentsFeature = AppModel.shared.momentsFeature) { self.moments = moments }
  func load() async { await moments.loadIfRequired() }
  func sourceNotice(for snapshot: MomentSnapshot) -> String? {
    switch moments.sourceState(for: snapshot) {
    case .unavailable, .current: return nil
    case .edited:
      return "This entry has since been edited. These are the words saved with this source."
    case .deleted:
      return
        "This entry has been deleted from your dataset. This saved source is a historical copy."
    }
  }
  func current(_ snapshot: MomentSnapshot) -> MomentSnapshot {
    moments.currentMoment(snapshot)
  }
}
