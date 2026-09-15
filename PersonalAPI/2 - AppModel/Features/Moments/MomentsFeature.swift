import Foundation

@MainActor protocol MomentsFeature: AnyObject, Sendable {
    var moments: [MomentSnapshot] { get }
    var isLoading: Bool { get }
    var loadError: String? { get }
    var enrichmentError: String? { get }
    func currentMoment(_ fallback: MomentSnapshot) -> MomentSnapshot
    func canRecord(_ text: String) -> Bool
    func loadIfRequired() async
    func refresh() async
    func recordMoment(text: String, happenedAt: Date?) async throws
    func updateMoment(_ original: MomentSnapshot, text: String) async throws
    func deleteMoment(_ original: MomentSnapshot) async throws
    func enrichPendingMoments() async
    func regenerateMetadata() async throws
}
