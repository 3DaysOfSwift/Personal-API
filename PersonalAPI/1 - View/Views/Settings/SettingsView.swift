import SwiftUI
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(ThemeManager.self) private var theme
    @State private var exporting = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    Toggle("Face ID / device passcode", isOn: Binding(get: { viewModel.lockEnabled }, set: { value in Task { await viewModel.setLockEnabled(value) } })).disabled(viewModel.authenticating)
                    Text("Locks when the app enters the background. Your preview is hidden whenever the app is inactive.").font(.footnote).foregroundStyle(theme.theme.secondary)
                    if let error = viewModel.authenticationError { Text(error).foregroundStyle(theme.theme.error) }
                }
                Section("Your data") {
                    LabeledContent("Storage", value: "On this device")
                    LabeledContent("iCloud sync", value: "Not configured")
                    Button("Export Personal API · JSON") {
                        Task { exporting = await viewModel.prepareExport() }
                    }.disabled(viewModel.isWorking)
                    Text("Includes original Moments, profile facts, IDs, dates and derived metadata. Save a copy somewhere you control.").font(.footnote).foregroundStyle(theme.theme.secondary)
                }
                Section("Intelligence") {
                    LabeledContent("Processor", value: "Local extractive v1")
                    Button("Regenerate derived metadata") { Task { await viewModel.regenerate() } }.disabled(viewModel.isWorking)
                    if let error = viewModel.enrichmentError { Text(error).foregroundStyle(theme.theme.error) }
                    Text("Original words are preserved. On-device AI enrichment is a future step.").font(.footnote).foregroundStyle(theme.theme.secondary)
                }
                Section("Personal API · 0.1") {
                    LabeledContent("Moments", value: "\(viewModel.momentCount)")
                    LabeledContent("Personal facts", value: "\(viewModel.factCount)")
                    Text("Build the dataset of yourself that future AI will be able to interrogate.")
                }
                #if DEBUG
                Section("Development appearance") {
                    Button("Midnight") { theme.theme = .midnight }
                    Button("Graphite") { theme.theme = .graphite }
                }
                #endif
                if viewModel.isWorking { ProgressView() }
                if let message = viewModel.message { Section { Text(message) } }
            }.scrollContentBackground(.hidden).background(theme.theme.background).navigationTitle("Settings")
            .fileExporter(isPresented: $exporting, document: viewModel.document, contentType: .json, defaultFilename: "PersonalAPI") { result in
                viewModel.exportFinished(result)
            }
        }
    }
}
