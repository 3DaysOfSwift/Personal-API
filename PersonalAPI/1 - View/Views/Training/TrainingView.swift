import SwiftUI

struct TrainingView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = TrainingViewModel()
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("TRAINING · BABY API").font(.caption).tracking(2).foregroundStyle(theme.theme.secondary)
                    Text("What happened?").font(.largeTitle.bold())
                    Text("A thought, an idea, a turning point. Keep your own words.").foregroundStyle(theme.theme.secondary)
                    TextEditor(text: $viewModel.text).frame(minHeight: 150).padding(12).scrollContentBackground(.hidden).background(theme.theme.surface, in: RoundedRectangle(cornerRadius: 18)).accessibilityLabel("Moment text").disabled(viewModel.isSaving)
                    Toggle("Add an event date", isOn: $viewModel.hasEventDate)
                    if viewModel.hasEventDate { DatePicker("When it happened", selection: $viewModel.eventDate, displayedComponents: .date) }
                    Button {
                        Task { await viewModel.save() }
                    } label: { Label("Log Moment", systemImage: "arrow.up").frame(maxWidth: .infinity).padding(8) }
                    .buttonStyle(.borderedProminent).disabled(!viewModel.canSave)
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                    if viewModel.isLoading { ProgressView("Loading Moments…") }
                    if let error = viewModel.loadError {
                        Text(error).foregroundStyle(theme.theme.error)
                        Button("Retry loading") { Task { await viewModel.retry() } }
                    }
                    if let error = viewModel.enrichmentError { Text(error).font(.footnote).foregroundStyle(theme.theme.secondary) }
                    Divider()
                    Text("RECENT MOMENTS · \(viewModel.moments.count)").font(.caption).tracking(2).foregroundStyle(theme.theme.secondary)
                    if viewModel.moments.isEmpty { Text("Your first Moment starts here.").foregroundStyle(theme.theme.secondary) }
                    ForEach(viewModel.moments) { moment in
                        NavigationLink { MomentDetailView(moment: moment) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(moment.createdAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(theme.theme.secondary)
                                Text(moment.text).lineLimit(4).foregroundStyle(theme.theme.primary).multilineTextAlignment(.leading)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                        }
                        Divider()
                    }
                }.padding(24)
            }.navigationTitle("Personal API").navigationBarTitleDisplayMode(.inline).task { await viewModel.load() }
        }
    }
}

