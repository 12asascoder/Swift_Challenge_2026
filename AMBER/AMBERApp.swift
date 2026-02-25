import SwiftUI

@main
struct AMBERApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootNavigationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            if appState.showMoodCheckIn {
                AvatarMoodCheckInView()
                    .transition(.move(edge: .bottom))
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.showMoodCheckIn)
    }
}
