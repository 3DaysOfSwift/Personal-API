import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var viewModel = ProfileViewModel()
    var body: some View {
        @Bindable var viewModel = viewModel
            Form {
                Section { Text("Teach your API the facts of your life. Start anywhere; you can keep adding over time.").foregroundStyle(theme.theme.secondary) }
                Section("Add a fact") {
                    Menu("Choose a suggested field") {
                        Section("Identity") {
                            ForEach(["First name", "Middle names", "Last name", "Preferred name", "Date of birth", "Pronouns", "Gender"], id: \.self) { field in
                                Button(field) { viewModel.label = field }
                            }
                        }
                        Section("Work and education") {
                            ForEach(["Occupation", "Employer", "Qualification"], id: \.self) { field in
                                Button(field) { viewModel.label = field }
                            }
                        }
                        Section("Places and relationships") {
                            ForEach(["Current address", "Previous address", "Important person"], id: \.self) { field in
                                Button(field) { viewModel.label = field }
                            }
                        }
                        Section("Interests and possessions") {
                            ForEach(["Hobby", "Preference", "Vehicle"], id: \.self) { field in
                                Button(field) { viewModel.label = field }
                            }
                        }
                    }.disabled(viewModel.isSaving)
                    Text("Every field is optional. Choose a suggestion or write your own label. Include dates in your answer when a fact changed—for example, ‘Teacher, 2012–2018; iOS developer since 2019.’")
                        .font(.footnote).foregroundStyle(theme.theme.secondary)
                    TextField("Label, e.g. Birthplace", text: $viewModel.label).disabled(viewModel.isSaving)
                    TextField("Your answer", text: $viewModel.value, axis: .vertical).disabled(viewModel.isSaving)
                    Button("Save fact") { Task { await viewModel.save() } }.disabled(!viewModel.canSave)
                    if let error = viewModel.error { Text(error).foregroundStyle(theme.theme.error) }
                }
                if viewModel.isLoading { ProgressView("Loading facts…") }
                if let error = viewModel.loadError {
                    Text(error).foregroundStyle(theme.theme.error)
                    Button("Retry loading") { Task { await viewModel.retry() } }
                }
                Section("Your facts") {
                    if viewModel.facts.isEmpty { Text("No facts yet.").foregroundStyle(theme.theme.secondary) }
                    ForEach(viewModel.facts) { fact in VStack(alignment: .leading, spacing: 6) { Text(fact.label).font(.caption).foregroundStyle(theme.theme.secondary); Text(fact.value).textSelection(.enabled) } }
                }
            }.scrollContentBackground(.hidden).background(theme.theme.background).task { await viewModel.load() }
    }
}
