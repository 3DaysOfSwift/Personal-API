import Foundation
@testable import PersonalAPI

enum TestFailure: Error { case unavailable }
actor MemoryRepository: PersonalDataRepository {
    var moments: [MomentSnapshot] = []
    var facts: [PersonalFactSnapshot] = []
    var fails = false
    var momentLoads = 0
    func setFailure(_ value: Bool) { fails = value }
    func loadMoments() throws -> [MomentSnapshot] { momentLoads += 1; if fails { throw TestFailure.unavailable }; return moments }
    func saveMoment(_ moment: MomentSnapshot) throws { if fails { throw TestFailure.unavailable }; moments.insert(moment, at: 0) }
    func saveAnalysis(_ analysis: MomentAnalysis, momentID: UUID) throws -> MomentSnapshot {
        if fails { throw TestFailure.unavailable }
        guard let index = moments.firstIndex(where: { $0.id == momentID }) else { throw MomentError.missingMoment }
        moments[index].analysisData = try JSONEncoder().encode(analysis)
        moments[index].processingState = "complete"
        return moments[index]
    }
    func markAnalysesPending() throws -> [MomentSnapshot] {
        if fails { throw TestFailure.unavailable }
        for index in moments.indices { moments[index].processingState = "pending" }
        return moments
    }
    func loadFacts() throws -> [PersonalFactSnapshot] { if fails { throw TestFailure.unavailable }; return facts }
    func saveFact(_ fact: PersonalFactSnapshot) throws { if fails { throw TestFailure.unavailable }; facts.insert(fact, at: 0) }
    func exportArchive() throws -> Data {
        if fails { throw TestFailure.unavailable }
        return try JSONEncoder().encode(PersonalArchive(exportedAt: Date(timeIntervalSince1970: 100), moments: moments.map(PersonalArchive.MomentRecord.init), facts: facts))
    }
}
@MainActor final class MemoryPreferences: PreferencesRepository {
    var onboarded = false
    var lockEnabled = false
}
@MainActor final class AuthenticationStub: DeviceAuthentication {
    var success = true
    var suspended = false
    var pending: CheckedContinuation<Bool, Error>?
    var calls = 0
    func authenticate() async throws -> Bool {
        calls += 1
        if suspended { return try await withCheckedThrowingContinuation { pending = $0 } }
        return success
    }
    func cancel() {} // Intentionally completes late to test the manager's generation guard.
    func complete() { pending?.resume(returning: success); pending = nil }
}
actor FailingProcessor: MomentProcessor {
    func analyse(_ input: MomentInput) throws -> MomentAnalysis { throw TestFailure.unavailable }
}
@MainActor struct TestAppModelFactory {
    let repository = MemoryRepository()
    let preferences = MemoryPreferences()
    let authentication = AuthenticationStub()
    let app: AppModel
    init(processor: (any MomentProcessor)? = nil) {
        let now: @Sendable () -> Date = { Date(timeIntervalSince1970: 1_000) }
        let moments = MomentsManager(repository: repository, processor: processor ?? LocalMomentProcessor(now: now), now: now)
        let profile = ProfileManager(repository: repository, now: now)
        app = AppModel(moments: moments, profile: profile,
                       query: QueryManager(repository: repository, retriever: MomentRetriever()),
                       authentication: AuthenticationManager(client: authentication, preferences: preferences),
                       settings: SettingsManager(preferences: preferences, repository: repository, moments: moments, profile: profile))
    }
}
