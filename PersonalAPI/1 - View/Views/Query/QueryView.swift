import SwiftUI

struct QueryView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = QueryViewModel()
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("BABY API · QUERY LAB").font(.caption).tracking(2).foregroundStyle(theme.theme.secondary)
                    Text("Ask about your life.").font(.largeTitle.bold())
                    Text("Ask in your own words. On-device AI finds relevant Moments and answers from your own words. If it’s unavailable, we’ll show keyword results instead.").foregroundStyle(theme.theme.secondary)
                    HStack {
                        TextField("Try an idea, a person, a place…", text: $viewModel.question, axis: .vertical).submitLabel(.search).onSubmit { viewModel.submitSearch() }
                        Button { viewModel.submitSearch() } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }.accessibilityLabel("Search Moments").disabled(!viewModel.canSearch)
                    }.padding(16).background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                    if viewModel.isSearching { ProgressView("Reading your Moments and preparing an answer…") }
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.searched {
                        Text(viewModel.submitted).font(.headline)
                        Text(viewModel.searchMethod).font(.caption).foregroundStyle(theme.theme.secondary)
                        if viewModel.hasAIAnswer { Text("AI answer").font(.headline) }
                        Text(viewModel.answer).textSelection(.enabled)
                        if let note = viewModel.answerNote { Text(note).font(.caption).foregroundStyle(theme.theme.secondary) }
                        if !viewModel.citations.isEmpty {
                            DisclosureGroup("Supporting words") {
                                ForEach(Array(viewModel.citations.enumerated()), id: \.offset) { _, citation in
                                    Text("“\(citation.quote)”").font(.callout).padding(.vertical, 6)
                                }
                            }
                        }
                        if !viewModel.results.isEmpty {
                            DisclosureGroup(viewModel.results.count == 1 ? "1 matching Moment" : "\(viewModel.results.count) matching Moments") {
                                ForEach(viewModel.results) { evidence in
                                    NavigationLink { MomentDetailView(moment: evidence.moment) } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(evidence.moment.text).lineLimit(5).multilineTextAlignment(.leading)
                                            Text(evidence.moment.createdAt, style: .date).font(.caption).foregroundStyle(theme.theme.secondary)
                                        }.padding(.vertical, 10)
                                    }
                                }
                            }
                            Text("Were these the right Moments?").font(.subheadline)
                            HStack {
                                Button("Useful") { viewModel.feedback = "Useful" }
                                Button("Missed the mark") { viewModel.feedback = "Missed the mark" }
                            }.buttonStyle(.bordered)
                            if let feedback = viewModel.feedback { Text("This session: \(feedback)").font(.caption).foregroundStyle(theme.theme.secondary) }
                        }
                        #if DEBUG
                        Text("Diagnostics: \(viewModel.results.count) / \(viewModel.searchedCount) retrieved · limit 20 · original sources · profile facts excluded").font(.caption).foregroundStyle(theme.theme.secondary)
                        #endif
                    }
                }.padding(24)
            }.navigationTitle("Query").navigationBarTitleDisplayMode(.inline).onDisappear { viewModel.cancelSearch() }
        }
    }
}
