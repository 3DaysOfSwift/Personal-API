import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct QueryView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = QueryViewModel()
    @State private var showsMemoryEntry = false
    @State private var memoryQuestion = ""
    @State private var showsHistory = false
    @State private var feedbackTurn: ChatTurn?
    @State private var feedbackReason = AnswerFeedback.Rating.inventedDetail
    @State private var feedbackText = ""
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var showsExport = false
    @State private var pendingDeletion: UUID?
    // The UIKit editor reports focus through its delegate. FocusState would be reset
    // by SwiftUI because this screen no longer contains a .focused SwiftUI field.
    @State private var isQuestionFocused = false

    @State private var submittedTurnCount: Int?
    @State private var submittedText = ""

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
                ChatScrollView(content: AnyView(
                    VStack(alignment: .leading, spacing: 28) {
                        if viewModel.turns.isEmpty {
                            Text("New Chat").font(.largeTitle.bold())
                            Text("Search your own personal API and ask questions about your life.")
                                .foregroundStyle(theme.theme.secondary)
                        }
                        // The draft keeps its row identity when it becomes a saved turn.
                        ForEach(0..<rowCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 24) {
                                let turn = index < viewModel.turns.count ? viewModel.turns[index] : nil
                                MomentTextEditor(
                                    text: turn.map { .constant($0.question) } ?? Binding(
                                        get: { submittedTurnCount == viewModel.turns.count ? submittedText : viewModel.question },
                                        set: { viewModel.question = $0 }),
                                    isEditing: turn == nil ? $isQuestionFocused : .constant(false),
                                    isEnabled: turn == nil && !viewModel.isBusy,
                                    textColor: UIColor(theme.theme.primary),
                                    placeholderColor: UIColor(theme.theme.secondary),
                                    surfaceColor: UIColor(theme.theme.surface),
                                    accentColor: UIColor(theme.theme.interactiveAccent),
                                    placeholderText: "Ask about your life…",
                                    onSend: { submitQuestion() },
                                    managesParentTouchDelay: false)
                                    .frame(height: 174)
                                if let turn {
                                if viewModel.activeTurnID == turn.id {
                                    ProgressView("Thinking…")
                                } else {
                                    Label("Personal API", systemImage: "sparkles").font(.headline)
                                    Text(viewModel.answer(for: turn)).textSelection(.enabled)
                                    if let details = viewModel.failureDetails(for: turn) {
                                        DisclosureGroup("What happened?") {
                                            Text(details).font(.caption)
                                        }.font(.subheadline).foregroundStyle(theme.theme.secondary)
                                    }
                                    if turn.result?.generatedAnswer?.contextLimited == true {
                                        Text("This answer used excerpts. Some journal text was outside the answer context.")
                                            .font(.caption).foregroundStyle(theme.theme.secondary)
                                    }
                                    if let result = turn.result, !result.evidence.isEmpty {
                                        DisclosureGroup("Sources") {
                                            ForEach(result.evidence) { evidence in
                                                NavigationLink {
                                                    if evidence.moment.source == "personal-fact" {
                                                        ScrollView {
                                                            Text(evidence.moment.text).textSelection(.enabled).padding(24)
                                                        }.navigationTitle("Fact").navigationBarTitleDisplayMode(.inline)
                                                    } else {
                                                        MomentDetailView(moment: evidence.moment)
                                                    }
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
                                            Label("Log a moment about this", systemImage: "square.and.pencil")
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
                                        }.font(.caption).buttonStyle(PersonalAPIButtonStyle(appearance: .bordered)).disabled(viewModel.isBusy)
                                        if turn.feedback != nil {
                                            Text("Feedback saved for this answer.").font(.caption)
                                                .foregroundStyle(theme.theme.secondary)
                                        }
                                    }
                                }
                                } else if !viewModel.isBusy {
                                    Button { submitQuestion() } label: {
                                        Label("Ask Personal API", systemImage: "arrow.up")
                                            .frame(maxWidth: .infinity).padding(8)
                                    }
                                    .buttonStyle(PersonalAPIButtonStyle(appearance: .filled))
                                    .disabled(!viewModel.canSearch)
                                }
                            }
                            .background {
                                if index == viewModel.turns.count {
                                    ChatDraftBounds().allowsHitTesting(false)
                                }
                            }
                            .id(index)
                        }
                        if viewModel.isBusy {
                            Button("Stop", systemImage: "stop.circle") { viewModel.cancelSearch() }
                        }
                        if let error = viewModel.error {
                            Text(error).foregroundStyle(theme.theme.error)
                            if !viewModel.loaded { Button("Retry loading chats") { Task { await viewModel.load() } } }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(theme)
                ))
                .onChange(of: viewModel.isBusy) { _, busy in
                    if !busy { submittedTurnCount = nil; submittedText = "" }
                }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PERSONAL API")
                        .font(.caption).tracking(4)
                        .foregroundStyle(theme.theme.secondary)
                        .accessibilityAddTraits(.isHeader)
                }
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
                if isQuestionFocused {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { isQuestionFocused = false } label: {
                            Text("Done").foregroundStyle(theme.theme.interactiveAccent).frame(minHeight: 40)
                        }
                            .buttonStyle(.plain)
                            .tint(theme.theme.interactiveAccent)
                            .accessibilityHint("Dismisses the keyboard")
                    }
                }
            }
            .navigationTitle("Personal API").navigationBarTitleDisplayMode(.inline)
            .task {
                // Focus tracks editing with software and hardware keyboards alike.
                await Task.yield()
                guard !Task.isCancelled else { return }
                await viewModel.load()
            }
            .onDisappear {
                isQuestionFocused = false
                viewModel.cancelSearch()
            }
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
                .toolbar { Button { showsHistory = false } label: {
                    Text("Done").foregroundStyle(theme.theme.interactiveAccent).frame(minHeight: 40)
                }.buttonStyle(.plain).tint(theme.theme.interactiveAccent) }
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
        // The native scroll configuration owns keyboard overlap and animation.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar(.visible, for: .tabBar)
    }
    private var rowCount: Int {
        let showDraft = !viewModel.isBusy || submittedTurnCount == viewModel.turns.count
        return viewModel.turns.count + (showDraft ? 1 : 0)
    }

    private func submitQuestion() {
        guard viewModel.canSearch else { return }
        submittedText = viewModel.question
        submittedTurnCount = viewModel.turns.count
        isQuestionFocused = false
        viewModel.submitSearch()
    }
}

/// Own the scroll view rather than changing SwiftUI's private scroll hierarchy.
/// Its insets and offset use the keyboard's native animation transaction.
private struct ChatScrollView: UIViewControllerRepresentable {
    let content: AnyView
    func makeUIViewController(context: Context) -> Controller { Controller(content: content) }
    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.host.rootView = content
    }
    final class Controller: UIViewController {
        let scrollView = UIScrollView()
        let host: UIHostingController<AnyView>
        private var keyboardIsVisible = false
        init(content: AnyView) {
            host = UIHostingController(rootView: content)
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("Use init(content:)") }
        deinit { NotificationCenter.default.removeObserver(self) }
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.delaysContentTouches = false
            scrollView.alwaysBounceVertical = true
            scrollView.keyboardDismissMode = .interactive
            scrollView.contentInsetAdjustmentBehavior = .never
            view.addSubview(scrollView)
            addChild(host)
            host.safeAreaRegions = []
            host.sizingOptions = [.intrinsicContentSize]
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(host.view)
            host.didMove(toParent: self)
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
            ])
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)),
                name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
        private func draftBounds(in view: UIView) -> ChatDraftBounds.Marker? {
            if let marker = view as? ChatDraftBounds.Marker { return marker }
            for child in view.subviews {
                if let marker = draftBounds(in: child) { return marker }
            }
            return nil
        }

        private func activeEditor(in view: UIView) -> UITextView? {
            if let editor = view as? UITextView, editor.isFirstResponder { return editor }
            for child in view.subviews {
                if let editor = activeEditor(in: child) { return editor }
            }
            return nil
        }

        @objc private func keyboardChanged(_ notification: Notification) {
            guard let window = view.window,
                  let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let scroll = scrollView
            view.layoutIfNeeded()
            let editor = activeEditor(in: scroll)
            guard editor != nil || keyboardIsVisible else { return }
            let keyboard = window.convert(value.cgRectValue, from: window.screen.coordinateSpace)
            let viewport = scroll.convert(scroll.bounds, to: window)
            // Floating keyboards don't obscure the entire bottom edge.
            let docked = keyboard.maxY >= window.bounds.maxY - 1 && keyboard.minY < viewport.maxY
            let overlap = docked ? max(0, viewport.maxY - keyboard.minY) : 0
            keyboardIsVisible = overlap > 0
            let automaticInset = max(0, scroll.adjustedContentInset.bottom - scroll.contentInset.bottom)
            let bottomInset = max(0, overlap - automaticInset)
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
            var options = UIView.AnimationOptions(rawValue: curve << 16)
            options.formUnion([.beginFromCurrentState, .allowUserInteraction])
            let changes = {
                scroll.contentInset.bottom = bottomInset
                scroll.verticalScrollIndicatorInsets.bottom = max(0, overlap - automaticInset)
                let minimumY = -scroll.adjustedContentInset.top
                let maximumY = max(minimumY, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
                var targetY = min(maximumY, max(minimumY, scroll.contentOffset.y))
                if let editor, overlap > 0 {
                    let rect: CGRect
                    if let group = self.draftBounds(in: scroll) {
                        rect = group.convert(group.bounds, to: scroll)
                    } else {
                        rect = editor.convert(editor.bounds, to: scroll)
                    }
                    // The marker covers both the editor and actual submit button.
                    let bottom = rect.maxY + 20
                    let visibleHeight = scroll.bounds.height - scroll.adjustedContentInset.bottom
                    targetY = min(maximumY, max(targetY, bottom - visibleHeight))
                }
                scroll.contentOffset = CGPoint(x: scroll.contentOffset.x, y: targetY)
            }
            if duration > 0 {
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: changes)
            } else {
                UIView.performWithoutAnimation(changes)
            }
        }
    }
}

/// Measures the complete draft row without publishing geometry into SwiftUI state.
private struct ChatDraftBounds: UIViewRepresentable {
    final class Marker: UIView { }
    func makeUIView(context: Context) -> Marker { Marker() }
    func updateUIView(_ view: Marker, context: Context) { }
}
