import Foundation

struct LifeMapCandidate: Codable, Sendable, Equatable {
  let title: String
  let passage: String
}
struct LifeMapPoint: Identifiable, Sendable {
  let id: String
  let title: String
  let passage: String
  let source: MomentSnapshot
}
@MainActor protocol LifeMapFeature: AnyObject {
  var points: [LifeMapPoint] { get }
  var entryCount: Int { get }
  var processedCount: Int { get }
  var attemptedCount: Int { get }
  var failedCount: Int { get }
  var isReading: Bool { get }
  var issue: String? { get }
  func refresh() async
}
protocol LifeMapExtracting: Sendable {
  func extract(_ text: String) async throws -> [LifeMapCandidate]
}
