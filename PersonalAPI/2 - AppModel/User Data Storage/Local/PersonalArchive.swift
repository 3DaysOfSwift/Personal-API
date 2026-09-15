import Foundation

/// Open export v1. Dates remain numeric seconds since 2001-01-01 UTC to retain precision.
struct PersonalArchive: Codable {
  var format = "Personal API"
  var schemaVersion = 1
  var exportedAt: Date
  var moments: [MomentRecord]
  var facts: [PersonalFactSnapshot]
  struct MomentRecord: Codable {
    var id: UUID
    var text: String
    var createdAt: Date
    var happenedAt: Date?
    var source: String
    var processingState: String
    var derived: MomentAnalysis?
    var derivedData: Data?
    init(_ moment: MomentSnapshot) {
      id = moment.id
      text = moment.text
      createdAt = moment.createdAt
      happenedAt = moment.happenedAt
      source = moment.source
      processingState = moment.processingState
      derived = moment.analysis
      derivedData = moment.analysisData
    }
  }
}
