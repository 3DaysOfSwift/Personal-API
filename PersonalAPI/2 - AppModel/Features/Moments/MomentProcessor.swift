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
    return MomentAnalysis(
      title: String(line.prefix(80)), processor: "extractive-local", processedAt: now())
  }
}

protocol JournalFactExtracting: Sendable {
  func extract(from moment: MomentSnapshot) async throws -> [PersonalFactSnapshot]
}

/// Conservative English indexing, not a claim that the author's statements are verified.
/// Keep whole paragraphs so negations, dates, and neighbouring qualifications survive.
actor LocalJournalFactExtractor: JournalFactExtracting {
  static let version = "explicit-passages-v1"
  private let now: @Sendable () -> Date
  init(now: @escaping @Sendable () -> Date) { self.now = now }

  func extract(from moment: MomentSnapshot) throws -> [PersonalFactSnapshot] {
    let topics: [(String, String)] = [
      (
        "Occupation work career",
        #"\b(my (job|occupation|profession|career)|i (work|worked|am employed|was employed))\b"#
      ),
      (
        "Preferences enjoyment interests",
        #"\bi (love|like|enjoy|hate|dislike|prefer|loved|liked|enjoyed|hated|disliked|used to)\b"#
      ),
      ("Residence address places", #"\bi (live|lived|reside|moved|grew up)\b"#),
      ("Education school", #"\bi (attend|attended|studied|graduated)\b"#),
      ("Possessions ownership", #"\bi (own|owned|drive|drove)\b"#),
      ("Personal background", #"\b(my name is|i was born|i am|i[’']m)\b"#),
    ]
    var facts: [PersonalFactSnapshot] = []
    var seen: Set<String> = []
    for paragraph in moment.text.components(separatedBy: .newlines) {
      try Task.checkCancellation()
      let passage = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
      // Never truncate a qualification to fit the query budget. Raw search remains available.
      guard !passage.isEmpty, passage.count <= 600, seen.insert(passage).inserted else { continue }
      let labels = topics.compactMap { label, pattern in
        passage.range(of: pattern, options: [.regularExpression, .caseInsensitive]) == nil
          ? nil : label
      }
      guard !labels.isEmpty else { continue }
      facts.append(
        PersonalFactSnapshot(
          id: UUID(), label: labels.joined(separator: "; "),
          value: passage, createdAt: now(),
          derivation: FactDerivation(
            momentID: moment.id,
            sourceText: moment.text, extractorVersion: Self.version)))
    }
    return facts
  }
}
