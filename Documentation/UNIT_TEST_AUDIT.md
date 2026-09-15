# Unit-test audit — 16 September 2026

## Result

All 13 ViewModels now have a dedicated `<ViewModelName>Tests.swift` file. The shared suite finishes with **128 passed, four skipped, zero failed** (132 tests discovered). The four skipped tests are opt-in live-AI checks; synthetic, deterministic unit tests do not require a model or journal data.

This pass added 44 tests and removed the former combined History/Feedback test, for a net increase of 43. New test files are registered in the Xcode test target as well as discovered by SwiftPM. No production Swift code changed in this pass.

## ViewModel inventory

Dedicated suites cover Export, Life Map, Conversation History, Answer Feedback, Query, Training, Journal Entries, Edit Journal Entry, Moment Detail, Settings, Root, Lock and Onboarding.

The new coverage includes export document lifecycle and overlapping preparation, Life Map progress and failure recovery, history load/delete success and failure, feedback persistence and retained drafts, chat intent submission/retry/cancellation, history selection, source fidelity, editor cancellation/discard/deletion, and settings results. Thin task-launching wrappers may share coverage with the behaviour they initiate; the existence of a suite does not claim every presentation permutation is tested.

## Feature-manager function and behaviour map

Private helpers are exercised through the public operation that owns them. Initializers are exercised through injected in-memory dependencies.

| Manager | Functions covered | Behavioural tests |
| --- | --- | --- |
| Moments | canRecord, sourceState, currentMoment, loadIfRequired, refresh, recordMoment, updateMoment, deleteMoment, enrichPendingMoments, regenerateMetadata | MomentsManagerTests covers validation, source states, load retry, committed text, timestamp, failed enrichment, retry, stale edits, update/delete failure. SettingsManagerTests exercises regeneration. MomentsRaceTests covers late analysis after deletion; existing edit-race test covers stale analysis. |
| Profile | canSave, loadIfRequired, refresh, addFact | ProfileManagerTests covers blank inputs, exact saved values/date, failed writes without publication, retry, cached load and explicit refresh. ProfileRaceTests covers overlapping writes/refresh and cancelled queued writes. |
| Query | canSearch, both search overloads | QueryManagerTests covers 1–500 validation, repository failure/recovery, context, source integrity, generated answers, abstention, fallback and cancellation. QueryRaceTests covers independent requests completing out of order. |
| Conversations | canSend, load, send, answerAgain, delete, recordFeedback, export; commit/generate indirectly | ConversationsManagerTests covers loading retry, invalid/missing requests, saved generation failures, export round-trip, feedback length bound, failed deletes, commit failure, answer retry and cancellation. ConversationsRaceTests covers conflicting actions while busy. |
| Authentication | loadPreference, unlock, setEnabled, lockForBackground; authenticate indirectly | AuthenticationManagerTests covers enable/disable persistence, rejected authentication, provider errors, late background completion. AuthenticationRaceTests covers cancelled late success. |
| Settings | loadPreference, completeOnboarding, exportDataset, regenerateMetadata; count/error projections | SettingsManagerTests covers reconstruction, shared counts, export failure, regeneration success/failure. SettingsRaceTests covers concurrent exports/preferences and reversed completion of distinct snapshots. |
| Life Map | refresh; publish indirectly | LifeMapTests covers empty data, cache stability, source validation, partial failure and repository recovery. LifeMapRaceTests covers refresh coalescing, deletion during extraction and cancelled late results. |

Coverage instrumentation found no unexecuted functions attributed to the seven feature-manager source files in this shared run. That is a cross-check, not proof of complete branch coverage or freedom from races. Device-only inference code and UI runtime behaviour require separate validation.

## Reproduction and limits

Run the shared package tests with code coverage enabled, or run the normal PersonalAPI Xcode test scheme on a working Simulator. The separate Race Conditions scheme selects the feature concurrency suites.

The macOS harness compiles the actual Model and ViewModel sources. It does not exercise SwiftUI rendering, UIKit keyboard interaction or the full iPhone build. The existing Simulator-runtime environment blocker remains unchanged.
