import Foundation

protocol MomentProcessor: Sendable {
    func analyse(_ input: MomentInput) async throws -> MomentAnalysis
}

/// A future availability-gated Foundation Models adapter implements the same boundary.
actor LocalMomentProcessor: MomentProcessor {
    private let now: @Sendable () -> Date
    init(now: @escaping @Sendable () -> Date) { self.now = now }
    func analyse(_ input: MomentInput) throws -> MomentAnalysis {
        try Task.checkCancellation()
        let line = input.text.split(whereSeparator: \.isNewline).first.map(String.init) ?? input.text
        return MomentAnalysis(title: String(line.prefix(80)), processor: "extractive-local", processedAt: now())
    }
}
