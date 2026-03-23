import SwiftUI
import SwiftData

@Observable
final class AppState {
    var chatDetent: PresentationDetent = .height(90)
    var pendingMessage: String?
}

struct ContentView: View {
    @State private var appState = AppState()
    @Query private var profiles: [UserProfile]

    private var needsOnboarding: Bool {
        guard let profile = profiles.first else { return true }
        return !profile.onboardingCompleted
    }

    var body: some View {
        if needsOnboarding {
            OnboardingView()
        } else {
            HomeView()
                .environment(appState)
        }
    }
}
