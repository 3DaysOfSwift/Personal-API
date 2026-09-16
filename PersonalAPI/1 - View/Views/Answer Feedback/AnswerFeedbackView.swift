import SwiftUI

struct AnswerFeedbackView: View {
  let conversationID: UUID
  let turnID: UUID
  @State private var viewModel = AnswerFeedbackViewModel()
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  var body: some View {
    @Bindable var viewModel = viewModel
    NavigationStack {
      Form {
        Group {
          Picker("What went wrong?", selection: $viewModel.reason) {
            Text("Invented a detail").tag(AnswerFeedback.Rating.inventedDetail)
            Text("Misunderstood my question").tag(AnswerFeedback.Rating.misunderstood)
            Text("Missing information").tag(AnswerFeedback.Rating.missingInformation)
          }
          TextField(
            "Tell us what was wrong (optional)", text: $viewModel.explanation, axis: .vertical)
          Text(
            "Saved locally to help evaluate answers. This does not train the AI or change your journal."
          ).font(.caption)
          if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
          Button("Save feedback") {
            viewModel.submit(conversationID: conversationID, turnID: turnID)
          }
          .disabled(viewModel.isSaving)
        }
        .listRowBackground(theme.theme.surface)
      }
      .scrollContentBackground(.hidden)
      .background(theme.theme.background)
      .toolbarBackground(theme.theme.background, for: .navigationBar)
      .navigationTitle("Answer feedback")
      .toolbar { Button("Cancel") { dismiss() } }
      .onChange(of: viewModel.saved) { if viewModel.saved { dismiss() } }
    }
  }
}
