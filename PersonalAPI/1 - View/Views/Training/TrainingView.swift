import SwiftUI
import UIKit

struct TrainingView: View {
  var presentedFromChat = false
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var viewModel = TrainingViewModel()
  var body: some View {
    @Bindable var viewModel = viewModel
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("A lifetime,\none Moment\nat a time.").font(.largeTitle.bold())
          JournalTextEditor(
            text: $viewModel.text, isEditing: $viewModel.isMomentFocused,
            isEnabled: !viewModel.isSaving,
            textColor: UIColor(theme.theme.primary),
            placeholderColor: UIColor(theme.theme.secondary),
            surfaceColor: UIColor(theme.theme.surface),
            accentColor: UIColor(theme.theme.interactiveAccent)
          )
          .frame(height: 174)
          Button {
            viewModel.requestSave()
          } label: {
            Label("Log Moment", systemImage: "arrow.up").frame(maxWidth: .infinity).padding(8)
          }
          .buttonStyle(PersonalAPIButtonStyle(appearance: .filled)).foregroundStyle(
            theme.theme.onAccent
          ).disabled(!viewModel.canSave)
          if viewModel.didSave {
            Text(
              !presentedFromChat
                ? "Moment saved." : "Moment saved. Return to Personal API and ask again."
            ).font(.subheadline)
          }
          if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
          if viewModel.isLoading { ProgressView("Loading Moments…") }
          if let error = viewModel.loadError {
            Text(error).foregroundStyle(theme.theme.error)
            Button("Retry loading") { viewModel.requestRetry() }
          }
          if let error = viewModel.enrichmentError {
            Text(error).font(.footnote).foregroundStyle(theme.theme.secondary)
          }
          Divider().padding(.top, 40)
          Text("RECENT MOMENTS · \(viewModel.moments.count)").font(.caption).tracking(2)
            .foregroundStyle(theme.theme.secondary)
          if viewModel.moments.isEmpty {
            Text("Your first Moment starts today.").foregroundStyle(theme.theme.secondary)
          }
          ForEach(viewModel.moments) { moment in
            NavigationLink {
              MomentDetailView(moment: moment)
                .toolbar(.visible, for: .navigationBar)
            } label: {
              VStack(alignment: .leading, spacing: 8) {
                Text(moment.createdAt, format: .dateTime.month().day().hour().minute()).font(
                  .caption
                ).foregroundStyle(theme.theme.secondary)
                Text(moment.text).lineLimit(4).foregroundStyle(theme.theme.primary)
                  .multilineTextAlignment(.leading)
              }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
            }
            Divider()
          }
        }.padding(24)
      }
      .background(theme.theme.background)
      .toolbarBackground(theme.theme.background, for: .navigationBar, .tabBar)
      .onChange(of: viewModel.dismissRequested) { dismiss() }
      .navigationTitle("Personal API").navigationBarTitleDisplayMode(.inline).task {
        await viewModel.load()
      }
      .scrollDismissesKeyboard(.interactively)
      .scrollBounceBehavior(.always, axes: .vertical)
      .toolbar(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("PERSONAL API").font(.caption).tracking(4)
            .foregroundStyle(theme.theme.secondary)
        }
        if viewModel.isMomentFocused || presentedFromChat {
          ToolbarItem(placement: .topBarTrailing) {
            DoneButton { viewModel.done() }
              .accessibilityHint(
                viewModel.isMomentFocused ? "Dismisses the keyboard" : "Closes the moment editor")
          }
        }
      }
    }
  }
}
