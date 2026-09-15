import Foundation

/// Regenerable, in-memory passage index. No model call is needed to choose candidates.
actor LocalQueryIndex {
    struct Selection: Sendable {
        let candidates: [MomentSnapshot]
        let previousQuestions: [String]
        let indexedPassageCount: Int
    }
    private struct IndexedPassage {
        let text: String
        let terms: Set<String>
    }
    private struct IndexedMoment {
        let text: String
        let passages: [IndexedPassage]
    }
    private var cache: [UUID: IndexedMoment] = [:]
    private let stop: Set<String> = [
        "what", "when", "where", "who", "which", "how", "why", "have", "has", "had",
        "did", "does", "do", "the", "and", "about", "my", "me", "i", "a", "an", "of",
        "to", "is", "was", "were", "are", "you", "your", "some", "it", "he", "she",
        "him", "her", "they", "them", "that", "this", "there", "then", "we", "our",
        "can", "could", "would", "tell", "please", "at", "in", "on", "for", "with",
        "be", "been", "from", "any", "all", "not", "yes", "no"
    ]
    // Vocabulary expands recall; it does not classify facts or assign life stages.
    private let vocabulary: [Set<String>] = [
        ["job", "work", "career", "occupation", "profession", "employed", "employment", "employer",
         "developer", "programmer", "engineer", "business", "salary"],
        ["school", "schooling", "primary", "classroom", "lessons", "headmaster", "pupil"],
        ["childhood", "child", "children", "kid", "kids", "young", "primary", "school"],
        ["enjoy", "enjoyed", "enjoyment", "like", "liked", "dislike", "disliked", "hate", "hated",
         "happy", "happiness", "fun", "feeling", "felt", "feel", "confused"],
        ["exercise", "fitness", "jogging", "jog", "running", "run", "gym", "swimming", "cycling"],
        ["hobby", "hobbies", "interest", "interests", "leisure", "gardening", "painting", "photography", "music"],
        ["entertainment", "movie", "movies", "cinema", "concert", "television", "game", "games"],
        ["growth", "learning", "learned", "learnt", "goal", "goals", "progress", "achievement"],
        ["friend", "friends", "friendship", "friendships"],
        ["travel", "trip", "holiday", "vacation", "visited"]
    ]
    private func tokens(_ text: String) -> Set<String> {
        Set(text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
    }
    func select(question: String, previousQuestions: [String], moments: [MomentSnapshot], facts: [PersonalFactSnapshot] = []) throws -> Selection {
        try Task.checkCancellation()
        let liveIDs = Set(moments.map(\.id))
        cache = cache.filter { liveIDs.contains($0.key) }
        for moment in moments {
            try Task.checkCancellation()
            if cache[moment.id]?.text != moment.text {
                let passages = SearchPassage.split([moment], length: 600, overlap: 100).map {
                    IndexedPassage(text: $0.text, terms: tokens($0.text))
                }
                cache[moment.id] = IndexedMoment(text: moment.text, passages: passages)
            }
        }
        let current = tokens(question).subtracting(stop)
        // Only reference-bearing follow-ups inherit context. Standalone topic changes do not.
        let references: Set<String> = ["it", "he", "she", "him", "her", "they", "them", "there", "then", "that", "those"]
        let needsContext = !tokens(question).isDisjoint(with: references)
        let history = needsContext ? Array(previousQuestions.suffix(4)) : []
        let historyTerms = history.reduce(into: Set<String>()) { $0.formUnion(tokens($1).subtracting(stop)) }
        let requested = current.union(historyTerms)
        let focusGroups = vocabulary.enumerated().filter {
            $0.offset != 3 && !$0.element.isDisjoint(with: requested)
        }.map(\.element)
        let focusTerms = focusGroups.reduce(into: Set<String>()) { $0.formUnion($1) }
        var expanded = requested
        for group in vocabulary where !group.isDisjoint(with: requested) { expanded.formUnion(group) }
        let broad = question.lowercased().contains("throughout") || question.lowercased().contains("over my life")
            || question.lowercased().contains("over time") || question.lowercased().contains("across my life")
        var ranked: [(moment: MomentSnapshot, text: String, score: Int, order: Int)] = []
        var sequence = 0
        for moment in moments {
            // Labels expand recall only. The model receives the original qualified passage,
            // never a generated value or a fact from a missing/edited source.
            let supported = facts.filter { $0.isSupported(by: moment) }
            for fact in supported {
                let terms = tokens(fact.label + " " + fact.value)
                let direct = terms.intersection(current).count
                let contextual = terms.intersection(historyTerms).count
                guard direct + contextual > 0,
                      focusTerms.isEmpty || !terms.isDisjoint(with: focusTerms) else { continue }
                ranked.append((moment, fact.value, direct * 6 + contextual * 3 + 2, sequence))
                sequence += 1
            }
            for passage in cache[moment.id]?.passages ?? [] {
                try Task.checkCancellation()
                let direct = passage.terms.intersection(current).count
                let contextual = passage.terms.intersection(historyTerms).count
                let related = passage.terms.intersection(expanded.subtracting(requested)).count
                let score = direct * 6 + contextual * 3 + min(related, 3)
                if score > 0 && (focusTerms.isEmpty || !passage.terms.isDisjoint(with: focusTerms)) {
                    ranked.append((moment, passage.text, score, sequence))
                }
                sequence += 1
            }
        }
        ranked.sort { $0.score == $1.score ? $0.order < $1.order : $0.score > $1.score }
        var selected: [(moment: MomentSnapshot, text: String, score: Int, order: Int)] = []
        var counts: [UUID: Int] = [:]
        for candidate in ranked {
            guard !selected.contains(where: { $0.moment.id == candidate.moment.id && $0.text == candidate.text }) else { continue }
            let count = counts[candidate.moment.id, default: 0]
            // Broad questions sample more entries instead of letting one long entry dominate.
            guard count < (broad ? 1 : 3) else { continue }
            selected.append(candidate)
            counts[candidate.moment.id] = count + 1
            if selected.count == 12 { break }
        }
        let snapshots = selected.map { candidate in
            MomentSnapshot(id: candidate.moment.id, text: candidate.text,
                createdAt: candidate.moment.createdAt, happenedAt: candidate.moment.happenedAt,
                source: candidate.moment.source, analysisData: nil, processingState: candidate.moment.processingState)
        }
        return Selection(candidates: snapshots, previousQuestions: history, indexedPassageCount: sequence)
    }
}
