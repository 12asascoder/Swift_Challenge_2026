import SwiftUI
import WidgetKit

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
                .onOpenURL { url in
                    guard url.scheme == "amber" else { return }
                    switch url.host {
                    case "focus": appState.startGame(.focusArena)
                    case "flow":  appState.startGame(.flowGrid)
                    default: break
                    }
                }
                .onAppear { 
                    applyWidgetSuggestion() 
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }

    private func applyWidgetSuggestion() {
        guard let session = SharedStore.load() else { return }
        appState.widgetStressLevel = session.stressLevel
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
