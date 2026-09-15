import SwiftUI
import UniformTypeIdentifiers

struct QueryView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = QueryViewModel()
    @State private var showsMemoryEntry = false
    @State private var memoryQuestion = ""
    @State private var showsTabs = false
    @State private var showsHistory = false
    @State private var feedbackTurn: ChatTurn?
    @State private var feedbackReason = AnswerFeedback.Rating.inventedDetail
    @State private var feedbackText = ""
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var showsExport = false
    @State private var pendingDeletion: UUID?
    @FocusState private var isQuestionFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        if viewModel.turns.isEmpty {
                            Text("Ask about your life.").font(.largeTitle.bold())
                            Text("A conversation grounded in your memories.")
                                .foregroundStyle(theme.theme.secondary)
                        }
                        ForEach(viewModel.turns) { turn in
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Spacer(minLength: 32)
                                    Text(turn.question).padding(16)
                                        .background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                                }
                                if viewModel.activeTurnID == turn.id {
                                    ProgressView("Thinking…")
                                } else {
                                    Label("Personal API", systemImage: "sparkles").font(.headline)
                                    Text(viewModel.answer(for: turn)).textSelection(.enabled)
                                    if turn.result?.generatedAnswer?.contextLimited == true {
                                        Text("This answer used excerpts. Some journal text was outside the answer context.")
                                            .font(.caption).foregroundStyle(theme.theme.secondary)
                                    }
                                    if let result = turn.result, !result.evidence.isEmpty {
                                        DisclosureGroup("Sources") {
                                            ForEach(result.evidence) { evidence in
                                                NavigationLink {
                                                    MomentDetailView(moment: evidence.moment)
                                                } label: {
                                                    Text(evidence.moment.text).lineLimit(3)
                                                        .multilineTextAlignment(.leading).padding(.vertical, 8)
                                                }
                                            }
                                        }.font(.subheadline).foregroundStyle(theme.theme.secondary)
                                    }
                                    if turn.id == viewModel.turns.last?.id {
                                        Button("Answer again", systemImage: "arrow.clockwise") { viewModel.answerAgain() }
                                            .disabled(viewModel.isBusy)
                                        Button {
                                            memoryQuestion = turn.question
                                            isQuestionFocused = false
                                            showsMemoryEntry = true
                                        } label: {
                                            Label("Log a memory about this", systemImage: "square.and.pencil")
                                        }.disabled(viewModel.isBusy)
                                        if turn.result?.needsMoreMemories == true {
                                            Text("The more you log, the more useful your Personal API can become.")
                                                .font(.caption).foregroundStyle(theme.theme.secondary)
                                        }
                                    }
                                    if turn.result?.generatedAnswer != nil {
                                        HStack {
                                            Button("Useful", systemImage: "hand.thumbsup") {
                                                Task { await viewModel.feedback(.useful, explanation: "", turnID: turn.id) }
                                            }
                                            Button("Not helpful", systemImage: "hand.thumbsdown") {
                                                feedbackText = ""; feedbackReason = .inventedDetail; feedbackTurn = turn
                                            }
                                        }.font(.caption).buttonStyle(.bordered).disabled(viewModel.isBusy)
                                        if turn.feedback != nil {
                                            Text("Feedback saved for this answer.").font(.caption)
                                                .foregroundStyle(theme.theme.secondary)
                                        }
                                    }
                                }
                            }.id(turn.id)
                        }
                        if let error = viewModel.error {
                            Text(error).foregroundStyle(theme.theme.error)
                            if !viewModel.loaded { Button("Retry loading chats") { Task { await viewModel.load() } } }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: viewModel.turns.count) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                .onChange(of: viewModel.activeTurnID) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                .onChange(of: viewModel.conversationID) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        TextField("Ask about your life…", text: $viewModel.question, axis: .vertical)
                            .lineLimit(1...5).focused($isQuestionFocused)
                            .submitLabel(.send).onSubmit { viewModel.submitSearch() }
                        if viewModel.isBusy {
                            Button("Stop", systemImage: "stop.circle") { viewModel.cancelSearch() }
                                .labelStyle(.iconOnly).font(.title).frame(minWidth: 44, minHeight: 44)
                        } else {
                            Button { viewModel.submitSearch() } label: {
                                Image(systemName: "arrow.up.circle.fill").font(.title).frame(minWidth: 44, minHeight: 44)
                            }.accessibilityLabel("Ask Personal API").disabled(!viewModel.canSearch)
                        }
                    }.padding(16)
                        .background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)
                    Color.clear.frame(height: isQuestionFocused ? 12 : 96)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("New chat", systemImage: "square.and.pencil") { viewModel.newChat() }
                        Button("Saved chats", systemImage: "clock") { showsHistory = true }
                        Button("Export chats", systemImage: "square.and.arrow.up") {
                            Task {
                                if let data = await viewModel.exportChats() {
                                    exportDocument = ExportDocument(data: data); showsExport = true
                                }
                            }
                        }
                    } label: { Image(systemName: "bubble.left.and.bubble.right").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Conversation menu").disabled(viewModel.isBusy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isQuestionFocused = false; showsTabs.toggle()
                    } label: {
                        Label(showsTabs ? "Hide tabs" : "Show tabs", systemImage: "square.grid.2x2")
                            .frame(minHeight: 44)
                    }.accessibilityLabel(showsTabs ? "Hide navigation tabs" : "Show navigation tabs")
                }
            }
            .onChange(of: isQuestionFocused) { _, focused in if focused { showsTabs = false } }
            .navigationTitle("Query").navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .onDisappear { viewModel.cancelSearch() }
        }
        .sheet(isPresented: $showsMemoryEntry) {
            TrainingView(questionPrompt: memoryQuestion)
        }
        .sheet(isPresented: $showsHistory) {
            NavigationStack {
                List {
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.conversations.isEmpty { Text("Your conversations will appear here.") }
                    ForEach(viewModel.conversations) { chat in
                        Button {
                            viewModel.open(chat.id); showsHistory = false
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(chat.title)
                                Text(chat.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }.swipeActions {
                            Button("Delete", role: .destructive) { pendingDeletion = chat.id }
                        }
                    }
                }
                .navigationTitle("Saved chats")
                .toolbar { Button("Done") { showsHistory = false } }
                .confirmationDialog("Delete this conversation? Your journal entries will remain.", isPresented: Binding(
                    get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
                )) {
                    Button("Delete conversation", role: .destructive) {
                        if let id = pendingDeletion { Task { await viewModel.delete(id) } }
                        pendingDeletion = nil
                    }
                }
            }
        }
        .sheet(item: $feedbackTurn) { turn in
            NavigationStack {
                Form {
                    Picker("What went wrong?", selection: $feedbackReason) {
                        Text("Invented a detail").tag(AnswerFeedback.Rating.inventedDetail)
                        Text("Misunderstood my question").tag(AnswerFeedback.Rating.misunderstood)
                        Text("Missing information").tag(AnswerFeedback.Rating.missingInformation)
                    }
                    TextField("Tell us what was wrong (optional)", text: $feedbackText, axis: .vertical)
                    Text("Saved locally to help evaluate answers. This does not train the AI or change your journal.")
                        .font(.caption)
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    Button("Save feedback") {
                        Task {
                            if await viewModel.feedback(feedbackReason, explanation: feedbackText, turnID: turn.id) { feedbackTurn = nil }
                        }
                    }
                }.navigationTitle("Answer feedback")
                    .toolbar { Button("Cancel") { feedbackTurn = nil } }
            }
        }
        .fileExporter(isPresented: $showsExport, document: exportDocument, contentType: .json,
                      defaultFilename: "PersonalAPI-Conversations") { result in
            if case .failure(let error) = result { viewModel.exportFailed(error) }
        }
        .toolbar(showsTabs ? .visible : .hidden, for: .tabBar)
    }
}
