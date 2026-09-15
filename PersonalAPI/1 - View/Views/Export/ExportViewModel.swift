import Foundation
import Observation

@MainActor @Observable final class ExportViewModel {
  var showsExporter = false
  func requestExport() { Task { showsExporter = await prepareExport() } }
  private let settings: any SettingsFeature
  private(set) var isExporting = false
  private(set) var filename = ExportDocument.datasetFilename()
  private(set) var document: ExportDocument?
  private(set) var message: String?
  init(settings: any SettingsFeature = AppModel.shared.settingsFeature) { self.settings = settings }
  var momentCount: Int { settings.momentCount }
  func prepareExport() async -> Bool {
    guard !isExporting else { return false }
    isExporting = true
    defer { isExporting = false }
    do {
      filename = ExportDocument.datasetFilename()
      document = ExportDocument(data: try await settings.exportDataset())
      message = nil
      return true
    } catch {
      document = nil
      message = "Couldn’t prepare your file. \(error.localizedDescription)"
      return false
    }
  }
  func exportFinished(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      message =
        "Your personal dataset is saved. Keep adding Moments and export a fresh copy whenever you’re ready."
    case .failure(let error): message = "Couldn’t save your file. \(error.localizedDescription)"
    }
    document = nil
  }
}
