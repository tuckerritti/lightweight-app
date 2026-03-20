import SwiftUI

@Observable
final class AppState {
    var chatDetent: PresentationDetent = .height(90)
    var pendingMessage: String?
}

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        TabView {
            HomeView()
                .toolbar(appState.chatDetent == .large ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            ExerciseLibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .tint(.black)
        .environment(appState)
    }
}
