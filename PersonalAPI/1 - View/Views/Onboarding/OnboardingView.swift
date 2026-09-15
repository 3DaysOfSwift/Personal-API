import SwiftUI
struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(ThemeManager.self) private var theme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("PERSONAL API").font(.caption).tracking(4).foregroundStyle(theme.theme.secondary)
                Text("A lifetime,\none Moment\nat a time.").font(.largeTitle.bold())
                Text("Build the dataset of yourself that future AI will be able to interrogate.").font(.title3)
                Text("Think in years, not days. Capture what matters. Your original words stay on this device, ready to export whenever you choose.").foregroundStyle(theme.theme.secondary)
                Button("Start your dataset") { viewModel.startDataset() }.buttonStyle(.borderedProminent).foregroundStyle(theme.theme.onAccent).frame(maxWidth: .infinity)
            }.padding(28).padding(.top, 60)
        }
    }
}
