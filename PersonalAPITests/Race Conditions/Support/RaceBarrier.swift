import XCTest

@testable import PersonalAPI

/// One-shot controlled suspension. Tests bound arrival waits with XCTest timeouts.
actor RaceBarrier {
  let entered: XCTestExpectation
  private var watchdog: Task<Void, Never>?
  private var released = false
  private var continuation: CheckedContinuation<Void, Never>?
  init(_ entered: XCTestExpectation) { self.entered = entered }
  func pause() async {
    entered.fulfill()
    if released { return }
    watchdog = Task {
      do { try await Task.sleep(for: .seconds(5)) } catch { return }
      XCTFail(
        "Controlled dependency was not released; check for a deadlock in the tested operation")
      release()
    }
    await withCheckedContinuation { continuation = $0 }
  }
  func release() {
    watchdog?.cancel()
    watchdog = nil
    released = true
    continuation?.resume()
    continuation = nil
  }
}
func raceMoment(_ text: String) -> MomentSnapshot {
  .init(
    id: UUID(), text: text, createdAt: Date(), happenedAt: nil, source: "journal",
    analysisData: nil, processingState: "pending")
}

/// Pauses one repository boundary without changing the repository's commit behaviour.
actor PausedRepository: PersonalDataRepository {
  enum Boundary { case factWrite, export }
  let base = MemoryRepository()
  let barrier: RaceBarrier
  let boundary: Boundary
  private var paused = false
  init(_ boundary: Boundary, barrier: RaceBarrier) {
    self.boundary = boundary
    self.barrier = barrier
  }
  func loadMoments() async throws -> [MomentSnapshot] { try await base.loadMoments() }
  func saveMoment(_ moment: MomentSnapshot) async throws { try await base.saveMoment(moment) }
  func updateMoment(_ original: MomentSnapshot, text: String) async throws -> MomentSnapshot {
    try await base.updateMoment(original, text: text)
  }
  func deleteMoment(_ original: MomentSnapshot) async throws {
    try await base.deleteMoment(original)
  }
  func saveAnalysis(_ analysis: MomentAnalysis, momentID: UUID) async throws -> MomentSnapshot {
    try await base.saveAnalysis(analysis, momentID: momentID)
  }
  func markAnalysesPending() async throws -> [MomentSnapshot] {
    try await base.markAnalysesPending()
  }
  func loadFacts() async throws -> [PersonalFactSnapshot] { try await base.loadFacts() }
  func saveFact(_ fact: PersonalFactSnapshot) async throws {
    if boundary == .factWrite && !paused {
      paused = true
      await barrier.pause()
    }
    try await base.saveFact(fact)
  }
  func replaceDerivedFacts(_ facts: [PersonalFactSnapshot], source: MomentSnapshot) async throws {
    try await base.replaceDerivedFacts(facts, source: source)
  }
  func exportArchive() async throws -> Data {
    let snapshot = try await base.exportArchive()
    if boundary == .export && !paused {
      paused = true
      await barrier.pause()
    }
    return snapshot
  }
}
