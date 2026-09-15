import SwiftUI

struct MomentDetailView: View {
    let moment: MomentSnapshot
    @State private var viewModel = MomentDetailViewModel()
    @Environment(ThemeManager.self) private var theme
    var body: some View {
        let moment = viewModel.current(moment)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(moment.text).font(.title3).textSelection(.enabled)
                Divider()
                LabeledContent("Captured", value: moment.createdAt.formatted())
                if let date = moment.happenedAt { LabeledContent("Event date · you provided", value: date.formatted(date: .abbreviated, time: .omitted)) }
                Text("Original text · \(moment.source)").font(.caption).foregroundStyle(theme.theme.secondary)
                if let issue = moment.analysisIssue { Text(issue).foregroundStyle(theme.theme.error) }
                if let analysis = moment.analysis {
                    Text("Derived metadata").font(.headline)
                    Text(analysis.title)
                    Text("\(analysis.processor) · v\(analysis.version)").font(.caption).foregroundStyle(theme.theme.secondary)
                    Text("This first processor creates a title from your words. Tags, emotions, significance and event extraction await on-device enrichment.").font(.footnote).foregroundStyle(theme.theme.secondary)
                } else { Text("Enrichment pending. Your original text is saved.").foregroundStyle(theme.theme.secondary) }
            }.padding(24)
        }.navigationTitle("Moment").navigationBarTitleDisplayMode(.inline)
    }
}
