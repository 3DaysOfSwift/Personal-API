import SwiftUI
import UIKit
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
                    TrainingView().tabItem { Label("Training", systemImage: "square.and.pencil") }.tag(1)
                    QueryView().tabItem {
                        Label {
                            Text("Personal API")
                        } icon: {
                            Image(uiImage: PersonalAPITabLogo.image)
                                .renderingMode(.original)
                        }
                    }.tag(2)
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
                }
            }
            if scenePhase != .active {
                Color.black.ignoresSafeArea().overlay {
                    VStack(spacing: 12) {
                        Image("PersonalAPIBrand")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .accessibilityHidden(true)
                        Text("PERSONAL API")
                            .font(.caption)
                            .tracking(4)
                            .foregroundStyle(theme.theme.secondary)
                    }
                    .padding(24)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.enteredBackground() }
        }
    }
}

/// Render the existing brand artwork at native tab-icon size, removing its generous
/// presentation margins so the fingerprint remains legible in the tab bar.
private enum PersonalAPITabLogo {
    static let image: UIImage = {
        guard let source = UIImage(named: "PersonalAPIBrand"), let cgImage = source.cgImage else {
            return UIImage()
        }
        let crop = CGRect(x: CGFloat(cgImage.width) * 0.20,
                          y: CGFloat(cgImage.height) * 0.12,
                          width: CGFloat(cgImage.width) * 0.58,
                          height: CGFloat(cgImage.height) * 0.71)
        guard let cropped = cgImage.cropping(to: crop) else { return source }
        let size = CGSize(width: 25, height: 30)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysOriginal)
    }()
}
