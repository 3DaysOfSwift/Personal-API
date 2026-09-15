import SwiftUI
import UIKit

struct TrainingView: View {
    var questionPrompt: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = TrainingViewModel()
    @State private var isMomentFocused = false
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A lifetime,\none Moment\nat a time.").font(.largeTitle.bold())
                    MomentTextEditor(text: $viewModel.text, isEditing: $isMomentFocused,
                                     isEnabled: !viewModel.isSaving,
                                     textColor: UIColor(theme.theme.primary),
                                     placeholderColor: UIColor(theme.theme.secondary),
                                     surfaceColor: UIColor(theme.theme.surface),
                                     accentColor: UIColor(theme.theme.interactiveAccent))
                        .frame(height: 174)
                    Button {
                        Task { await viewModel.save() }
                    } label: { Label("Log Moment", systemImage: "arrow.up").frame(maxWidth: .infinity).padding(8) }
                    .buttonStyle(PersonalAPIButtonStyle(appearance: .filled)).foregroundStyle(theme.theme.onAccent).disabled(!viewModel.canSave)
                    if viewModel.didSave {
                        Text(questionPrompt == nil ? "Moment saved." : "Moment saved. Return to Personal API and ask again.").font(.subheadline)
                    }
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.isLoading { ProgressView("Loading Moments…") }
                    if let error = viewModel.loadError {
                        Text(error).foregroundStyle(theme.theme.error)
                        Button("Retry loading") { Task { await viewModel.retry() } }
                    }
                    if let error = viewModel.enrichmentError { Text(error).font(.footnote).foregroundStyle(theme.theme.secondary) }
                    Divider().padding(.top, 40)
                    Text("RECENT MOMENTS · \(viewModel.moments.count)").font(.caption).tracking(2).foregroundStyle(theme.theme.secondary)
                    if viewModel.moments.isEmpty { Text("Your first Moment starts today.").foregroundStyle(theme.theme.secondary) }
                    ForEach(viewModel.moments) { moment in
                        NavigationLink {
                            MomentDetailView(moment: moment)
                                .toolbar(.visible, for: .navigationBar)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(moment.createdAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(theme.theme.secondary)
                                Text(moment.text).lineLimit(4).foregroundStyle(theme.theme.primary).multilineTextAlignment(.leading)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                        }
                        Divider()
                    }
                }.padding(24)
            }.navigationTitle("Personal API").navigationBarTitleDisplayMode(.inline).task { await viewModel.load() }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.always, axes: .vertical)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PERSONAL API").font(.caption).tracking(4)
                        .foregroundStyle(theme.theme.secondary)
                }
                if isMomentFocused || questionPrompt != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if isMomentFocused { isMomentFocused = false }
                            else { dismiss() }
                        } label: {
                            Text("Done").foregroundStyle(theme.theme.interactiveAccent).frame(minHeight: 40)
                        }
                        .buttonStyle(.plain)
                        .tint(theme.theme.interactiveAccent)
                        .accessibilityHint(isMomentFocused ? "Dismisses the keyboard" : "Closes the moment editor")
                    }
                }
            }
        }
    }
}


/// The full rounded surface is the text view, including its internal padding.
/// Native text selection and scrolling handle touches without an extra tap recognizer.
struct MomentTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    let isEnabled: Bool
    let textColor: UIColor
    let placeholderColor: UIColor
    let surfaceColor: UIColor
    let accentColor: UIColor
    var placeholderText = "Write about a moment in your life. In detail."
    var onSend: (() -> Void)? = nil
    var managesParentTouchDelay = true

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> Editor {
        let view = Editor()
        view.managesParentTouchDelay = managesParentTouchDelay
        view.delegate = context.coordinator
        return view
    }
    func updateUIView(_ view: Editor, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if view.text != text { view.text = text }
        view.placeholder.text = placeholderText
        view.returnKeyType = onSend == nil ? .default : .send
        view.placeholder.isHidden = !text.isEmpty
        view.isEditable = isEnabled
        view.textColor = textColor
        view.placeholder.textColor = placeholderColor
        view.backgroundColor = surfaceColor
        view.tintColor = accentColor
        // Only Done requests a resignation. Native touches own acquisition of focus.
        // Never change the responder synchronously inside a SwiftUI update.
        if !isEditing && view.isFirstResponder {
            DispatchQueue.main.async { [weak view, weak coordinator] in
                guard let view, let coordinator, !coordinator.parent.isEditing else { return }
                view.resignFirstResponder()
            }
        }
    }
    static func dismantleUIView(_ view: Editor, coordinator: Coordinator) {
        view.delegate = nil
        view.restoreScrollTouchDelay()
    }
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MomentTextEditor
        init(_ parent: MomentTextEditor) { self.parent = parent }
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n", let onSend = parent.onSend { onSend(); return false }
            return true
        }
        func textViewDidChange(_ textView: UITextView) {
            (textView as? Editor)?.placeholder.isHidden = !textView.text.isEmpty
            parent.text = textView.text
        }
        func textViewDidBeginEditing(_ textView: UITextView) { parent.isEditing = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.isEditing = false }
    }
    final class Editor: UITextView {
        let placeholder = UILabel()
        var managesParentTouchDelay = true
        private weak var containingScrollView: UIScrollView?
        // Several chat editors can share one enclosing scroll view. Restore its
        // original behaviour only when the final editor releases it.
        private final class TouchDelayLease {
            let originalValue: Bool
            var users = 1
            init(originalValue: Bool) { self.originalValue = originalValue }
        }
        private static let touchDelayLeases = NSMapTable<UIScrollView, TouchDelayLease>(
            keyOptions: .weakMemory, valueOptions: .strongMemory)

        init() {
            super.init(frame: .zero, textContainer: nil)
            font = .preferredFont(forTextStyle: .body)
            adjustsFontForContentSizeCategory = true
            textContainerInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
            layer.cornerRadius = 18
            clipsToBounds = true
            keyboardDismissMode = .interactive
            delaysContentTouches = false
            accessibilityLabel = "Moment text"
            placeholder.text = "Write about a moment in your life. In detail."
            placeholder.font = font
            placeholder.adjustsFontForContentSizeCategory = true
            placeholder.numberOfLines = 0
            placeholder.isUserInteractionEnabled = false
            placeholder.isAccessibilityElement = false
            addSubview(placeholder)
        }
        required init?(coder: NSCoder) { fatalError("Use init()") }
        override func layoutSubviews() {
            super.layoutSubviews()
            let x = textContainerInset.left + textContainer.lineFragmentPadding
            let width = max(0, bounds.width - x - textContainerInset.right - textContainer.lineFragmentPadding)
            placeholder.frame = CGRect(x: x, y: textContainerInset.top, width: width,
                height: placeholder.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            restoreScrollTouchDelay()
            guard window != nil, managesParentTouchDelay else { return }
            var ancestor = superview
            while let candidate = ancestor {
                if let scroll = candidate as? UIScrollView {
                    containingScrollView = scroll
                    if let lease = Self.touchDelayLeases.object(forKey: scroll) {
                        lease.users += 1
                    } else {
                        Self.touchDelayLeases.setObject(TouchDelayLease(originalValue: scroll.delaysContentTouches), forKey: scroll)
                    }
                    scroll.delaysContentTouches = false
                    break
                }
                ancestor = candidate.superview
            }
        }
        func restoreScrollTouchDelay() {
            if let scroll = containingScrollView,
               let lease = Self.touchDelayLeases.object(forKey: scroll) {
                lease.users -= 1
                if lease.users == 0 {
                    scroll.delaysContentTouches = lease.originalValue
                    Self.touchDelayLeases.removeObject(forKey: scroll)
                }
            }
            containingScrollView = nil
        }
    }
}
