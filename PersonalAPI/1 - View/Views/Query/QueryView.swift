import SwiftUI

struct QueryView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = QueryViewModel()
    @State private var showsTabs = false
    @FocusState private var isQuestionFocused: Bool
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !viewModel.searched && !viewModel.isSearching {
                        Text("Ask about your life.").font(.largeTitle.bold())
                        Text("A conversation grounded in your memories.")
                            .foregroundStyle(theme.theme.secondary)
                    }
                    if viewModel.isSearching || viewModel.searched {
                        HStack {
                            Spacer(minLength: 32)
                            Text(viewModel.submitted).padding(16)
                                .background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    if viewModel.isSearching { ProgressView("Thinking…") }
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.searched {
                        Label("Personal API", systemImage: "sparkles").font(.headline)
                        Text(viewModel.answer).textSelection(.enabled)
                        if let note = viewModel.answerNote {
                            Text(note).font(.caption).foregroundStyle(theme.theme.secondary)
                        }
                        if !viewModel.hasAIAnswer && !viewModel.results.isEmpty {
                            Button("Retry answer") { viewModel.retryAnswer() }.buttonStyle(.bordered)
                        }
                        if !viewModel.results.isEmpty {
                            DisclosureGroup("Sources") {
                                Text(viewModel.searchMethod).font(.caption).foregroundStyle(theme.theme.secondary)
                                ForEach(viewModel.results) { evidence in
                                    NavigationLink { MomentDetailView(moment: evidence.moment) } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(evidence.moment.text).lineLimit(3).multilineTextAlignment(.leading)
                                            Text(evidence.moment.createdAt, style: .date).font(.caption)
                                        }.padding(.vertical, 10)
                                    }
                                }
                            }.font(.subheadline).foregroundStyle(theme.theme.secondary)
                        }
                        if viewModel.hasAIAnswer {
                            HStack {
                                Button("Useful answer", systemImage: "hand.thumbsup") { viewModel.feedback = "Useful" }
                                Button("Not helpful", systemImage: "hand.thumbsdown") { viewModel.feedback = "Not helpful" }
                            }.font(.caption).buttonStyle(.bordered)
                            if let feedback = viewModel.feedback {
                                Text("This session: \(feedback)").font(.caption).foregroundStyle(theme.theme.secondary)
                            }
                        }
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        TextField("Ask about your life…", text: $viewModel.question, axis: .vertical)
                            .lineLimit(1...5).focused($isQuestionFocused)
                            .submitLabel(.send).onSubmit { viewModel.submitSearch() }
                        Button { viewModel.submitSearch() } label: {
                            Image(systemName: "arrow.up.circle.fill").font(.title)
                                .frame(minWidth: 44, minHeight: 44)
                        }.accessibilityLabel("Ask Personal API").disabled(!viewModel.canSearch)
                    }
                    .padding(16)
                    .background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 20)
                    // Keep the resting composer comfortably above bottom navigation.
                    // With the keyboard open, its safe area already lifts the composer.
                    Color.clear.frame(height: isQuestionFocused ? 12 : 96)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isQuestionFocused = false
                        showsTabs.toggle()
                    } label: {
                        Label(showsTabs ? "Hide tabs" : "Show tabs", systemImage: "square.grid.2x2")
                            .font(.subheadline)
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel(showsTabs ? "Hide navigation tabs" : "Show navigation tabs")
                    .accessibilityHint("Show tabs to switch to Profile, Training or Settings")
                }
            }
            .onChange(of: isQuestionFocused) { _, focused in
                if focused { showsTabs = false }
            }
            .navigationTitle("Query").navigationBarTitleDisplayMode(.inline)
            .onDisappear { viewModel.cancelSearch() }
        }
        .toolbar(showsTabs ? .visible : .hidden, for: .tabBar)
    }
}
