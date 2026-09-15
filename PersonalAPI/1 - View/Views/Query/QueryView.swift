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
                    Text("Search your Moments using words you remember. This prototype finds exact keywords; it doesn’t reason about your life yet.").foregroundStyle(theme.theme.secondary)
                    HStack {
                        TextField("Try an idea, a person, a place…", text: $viewModel.question, axis: .vertical).submitLabel(.search).onSubmit { viewModel.submitSearch() }
                        Button { viewModel.submitSearch() } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }.accessibilityLabel("Search Moments").disabled(!viewModel.canSearch)
                    }.padding(16).background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                    if viewModel.isSearching { ProgressView("Searching Moments…") }
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.searched {
                        Text(viewModel.submitted).font(.headline)
                        Text(viewModel.answer)
                        if !viewModel.results.isEmpty {
                            DisclosureGroup("Based on \(viewModel.results.count) Moments") {
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
                        Text("Diagnostics: \(viewModel.results.count) / \(viewModel.searchedCount) retrieved · keyword overlap · limit 20 · no generated answer · profile facts excluded").font(.caption).foregroundStyle(theme.theme.secondary)
                        #endif
                    }
                }.padding(24)
            }.navigationTitle("Query").navigationBarTitleDisplayMode(.inline).onDisappear { viewModel.cancelSearch() }
        }
    }
}
