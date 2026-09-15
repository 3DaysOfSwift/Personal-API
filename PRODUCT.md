# Personal API

> Build the dataset of yourself that future AI will be able to interrogate.

A private lifetime dataset, built one Moment at a time. Training stays useful forever. Think in years, not days; usefulness depends on the evidence accumulated, not a gamified score.

## Rules of the product

- The user owns the dataset. No developer server receives life data.
- Original user input is canonical. Never replace it with an AI summary, inferred emotion or generated tag.
- Save raw Moments before attempting enrichment. Processing failure must never lose a thought.
- Derived metadata and future indexes are disposable and regenerable from original sources. Record the processor and version.
- Open export is a core feature. Stable IDs, original text, source, timestamps and profile facts must leave the app intact.
- Answers must expose their evidence. Retrieved text and inferred conclusions are different things. Abstain when evidence is missing; do not manufacture personal history or causal explanations.
- Privacy is architectural. Collection should be deliberate, minimal and understandable.
- iCloud, when added, is synchronization through the user’s account. Do not claim it is a backup or enabled until configured and verified.

## Version 0.1: the complete loop

1. Introduce the long-term purpose with one onboarding screen.
2. Add labelled profile facts, or log a Moment with an optional user-provided event date.
3. Commit original text to local SwiftData storage immediately.
4. Produce an extractive title through the interchangeable Moment Processor boundary.
5. Query original Moments by keywords; inspect every matching source.
6. Export the complete current dataset as versioned JSON.

Four tabs: Profile, Training (initial tab), Query, Settings. Dark mode only, content first, restrained typography and controls. Query is available from the first entry so ingestion/retrieval can be evaluated immediately.

## Honest boundaries

The current processor is deterministic and only extracts a title. The schema has space for factual tags, categories, themes, emotions, significance, life-event classification and evidence-supported event-date extraction. Foundation Models enrichment is not implemented yet.

Query is exact keyword overlap, capped at 20 results. It does not understand dates, synonyms, negation or natural-language reasoning. It searches Moments only; profile facts are stored and exported but not retrieved yet. Feedback is session-local.

Face ID/device-passcode lock and inactive-screen concealment are included. This is an application access gate, not a separately encrypted vault. Exported JSON is plaintext and outside the app lock.

No iCloud synchronization, import, HealthKit, attachments, semantic index, network service or generative answering in 0.1. Profile corrections, Moment deletion and portable archive import are subsequent work. Do not market this prototype as a sole lifetime archive; users can export now.

## Next acceptance milestones

- Real-device capture, restart, lock/unlock and export verification.
- Import/export round trips with conflict handling and schema migrations.
- Availability-gated on-device structured enrichment with source spans and uncertainty.
- Semantic retrieval evaluated against a small labelled collection of known questions and source IDs.
- Evidence-grounded synthesis evaluated separately from retrieval.
- Opt-in private iCloud synchronization after account, conflict and migration testing.
