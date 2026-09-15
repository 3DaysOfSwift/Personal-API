import SwiftUI
struct LockView: View {
    @State private var viewModel = LockViewModel()
    @Environment(ThemeManager.self) private var theme
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill").font(.largeTitle)
            Text("Your life. Yours alone.").font(.title2)
            Button("Unlock Personal API") { Task { await viewModel.unlock() } }.buttonStyle(PersonalAPIButtonStyle(appearance: .filled)).foregroundStyle(theme.theme.onAccent).disabled(viewModel.authenticating)
            if let error = viewModel.error { Text(error).font(.footnote).foregroundStyle(theme.theme.error) }
        }.padding()
    }
}
