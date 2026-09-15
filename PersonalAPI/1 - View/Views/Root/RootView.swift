import SwiftUI
struct RootView: View {
    @State private var viewModel = RootViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ThemeManager.self) private var theme
    @State private var tab = 1
    var body: some View {
        ZStack {
            theme.theme.background.ignoresSafeArea()
            if viewModel.requiresUnlock { LockView() }
            else if viewModel.needsOnboarding { OnboardingView() }
            else {
                TabView(selection: $tab) {
                    ProfileView().tabItem { Label("Profile", systemImage: "person") }.tag(0)
                    TrainingView().tabItem { Label("Training", systemImage: "square.and.pencil") }.tag(1)
                    QueryView().tabItem { Label("Query", systemImage: "bubble.left") }.tag(2)
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
                }
            }
            if scenePhase != .active {
                theme.theme.background.ignoresSafeArea().overlay { Text("Personal API").font(.title2) }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.enteredBackground() }
        }
    }
}
