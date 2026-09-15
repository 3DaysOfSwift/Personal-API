import Foundation
import Observation

@MainActor @Observable final class SettingsViewModel {
  var exporting = false
  func requestExport() { Task { exporting = await prepareExport() } }
  private let settings: any SettingsFeature
  private let authentication: any AuthenticationFeature
  private(set) var isWorking = false
  private(set) var message: String?
  private(set) var filename = ExportDocument.datasetFilename()
  private(set) var document: ExportDocument?
  init(
    settings: any SettingsFeature = AppModel.shared.settingsFeature,
    authentication: any AuthenticationFeature = AppModel.shared.authenticationFeature
  ) {
    self.settings = settings
    self.authentication = authentication
  }
  var lockEnabled: Bool { authentication.enabled }
  var authenticating: Bool { authentication.authenticating }
  var authenticationError: String? { authentication.error }
  var enrichmentError: String? { settings.enrichmentError }
  var momentCount: Int { settings.momentCount }
  var factCount: Int { settings.factCount }
  func requestLockEnabled(_ value: Bool) { Task { await setLockEnabled(value) } }
  func setLockEnabled(_ enabled: Bool) async { await authentication.setEnabled(enabled) }
  func prepareExport() async -> Bool {
    guard !isWorking else { return false }
    isWorking = true
    defer { isWorking = false }
    do {
      filename = ExportDocument.datasetFilename()
      document = ExportDocument(data: try await settings.exportDataset())
      message = nil
      return true
    } catch {
      document = nil
      message = error.localizedDescription
      return false
    }
  }
  func exportFinished(_ result: Result<URL, Error>) {
    switch result {
    case .success: message = "Export saved."
    case .failure(let error): message = "Export failed: \(error.localizedDescription)"
    }
    document = nil
  }
  func regenerate() async {
    guard !isWorking else { return }
    isWorking = true
    defer { isWorking = false }
    do {
      try await settings.regenerateMetadata()
      message = settings.enrichmentError ?? "Derived metadata regenerated."
    } catch { message = error.localizedDescription }
  }
  func requestRegenerate() { Task { await regenerate() } }
}
