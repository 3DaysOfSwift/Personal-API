import SwiftUI

struct EditJournalEntryView: View {
    let entry: MomentSnapshot
    @State private var viewModel = EditJournalEntryViewModel()
    @State private var editing = false
    @State private var confirmingDelete = false
    @State private var confirmingDiscard = false
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline).foregroundStyle(theme.theme.secondary)
                MomentTextEditor(text: $viewModel.text, isEditing: $editing,
                                 isEnabled: !viewModel.isWorking,
                                 textColor: UIColor(theme.theme.primary),
                                 placeholderColor: UIColor(theme.theme.secondary),
                                 surfaceColor: UIColor(theme.theme.surface),
                                 accentColor: UIColor(theme.theme.interactiveAccent))
                    .frame(minHeight: 260).disabled(viewModel.isWorking)
                Text("Saving updates this journal entry and refreshes its derived information. Its original recorded date stays the same.")
                    .font(.footnote).foregroundStyle(theme.theme.secondary)
                Button("Save changes") {
                    editing = false
                    Task { if await viewModel.save() { dismiss() } }
                }.buttonStyle(PersonalAPIButtonStyle(appearance: .filled)).disabled(!viewModel.canSave)
                if viewModel.isWorking { ProgressView() }
                if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                Divider()
                Button("Delete journal entry", role: .destructive) { confirmingDelete = true }
                    .disabled(viewModel.isWorking)
            }.padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(theme.theme.background)
        .navigationTitle("Edit entry").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    if viewModel.hasChanges { confirmingDiscard = true } else { dismiss() }
                }.disabled(viewModel.isWorking).tint(theme.theme.interactiveAccent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if editing {
                    Button { editing = false } label: {
                        Text("Done").foregroundStyle(theme.theme.interactiveAccent)
                            .padding(.horizontal, 12).frame(minHeight: 40)
                    }.buttonStyle(.plain)
                }
            }
        }
        .onAppear { viewModel.prepare(entry) }
        .confirmationDialog("Delete this journal entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete entry", role: .destructive) {
                editing = false
                Task { if await viewModel.delete() { dismiss() } }
            }
        } message: {
            Text("This permanently removes the entry and its derived facts from your dataset. Saved chat conversations and previously exported files are kept.")
        }
        .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
        }
    }
}
