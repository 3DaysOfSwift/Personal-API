import Foundation
import Observation

@MainActor @Observable final class LifeMapViewModel {
  private let feature: any LifeMapFeature
  init(feature: any LifeMapFeature = AppModel.shared.lifeMapFeature) { self.feature = feature }
  var points: [LifeMapPoint] { feature.points }
  var entryCount: Int { feature.entryCount }
  var processedCount: Int { feature.processedCount }
  var attemptedCount: Int { feature.attemptedCount }
  var failedCount: Int { feature.failedCount }
  var isReading: Bool { feature.isReading }
  var issue: String? { feature.issue }
  func refresh() async { await feature.refresh() }
  func requestRefresh() { Task { await refresh() } }
}
