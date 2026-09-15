import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = ProfileViewModel()
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section { Text("Teach your API the facts of your life. Start anywhere; you can keep adding over time.").foregroundStyle(theme.theme.secondary) }
                Section("Add a fact") {
                    TextField("Label, e.g. Birthplace", text: $viewModel.label).disabled(viewModel.isSaving)
                    TextField("Your answer", text: $viewModel.value, axis: .vertical).disabled(viewModel.isSaving)
                    Button("Save fact") { Task { await viewModel.save() } }.disabled(!viewModel.canSave)
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                }
                if viewModel.isLoading { ProgressView("Loading profile…") }
                if let error = viewModel.loadError {
                    Text(error).foregroundStyle(theme.theme.error)
                    Button("Retry loading") { Task { await viewModel.retry() } }
                }
                Section("Your profile") {
                    if viewModel.facts.isEmpty { Text("No facts yet.").foregroundStyle(theme.theme.secondary) }
                    ForEach(viewModel.facts) { fact in VStack(alignment: .leading, spacing: 6) { Text(fact.label).font(.caption).foregroundStyle(theme.theme.secondary); Text(fact.value).textSelection(.enabled) } }
                }
            }.scrollContentBackground(.hidden).background(theme.theme.background).navigationTitle("Profile").task { await viewModel.load() }
        }
    }
}
