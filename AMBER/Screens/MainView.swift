import SwiftUI

// MARK: - Main Layout
struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.amberBG.ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .home:         HomeHubView()
                case .stats:        StatsView()
                case .achievements: AchievementsView()
                case .profile:      ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AMBERTabBar(selected: $appState.selectedTab)
        }
        .fullScreenCover(item: $appState.activeGame) { game in
            switch game {
        case .focusArena:    FocusArenaView()
            case .flowGrid:      FlowGridView()
            case .zenCanvas:     ZenCanvasView()
            case .structureMode: StructureModeView()
            case .harmonyMode:   HarmonyModeView()
            }
        }
        .sheet(isPresented: $appState.showSessionSummary) {
            SessionSummaryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .onAppear {
            if let m = appState.selectedMood, m == .low || m == .overwhelmed {
                AudioManager.shared.playCalmLoop(volume: 0.35)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if let m = appState.selectedMood, m == .low || m == .overwhelmed {
                    AudioManager.shared.playCalmLoop(volume: 0.35)
                }
            } else if newPhase == .background {
                AudioManager.shared.stop()
            }
        }
    }
}

// MARK: - Placeholder Views
struct StatsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundColor(.amberAccent)
            Text("Stats").font(.title2.bold()).foregroundColor(.white)
            Text("Coming soon").foregroundColor(.amberSubtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.amberBG)
    }
}

struct AchievementsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(.amberAccent)
            Text("Achievements").font(.title2.bold()).foregroundColor(.white)
            Text("Coming soon").foregroundColor(.amberSubtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.amberBG)
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(.amberAccent)
            Text("Profile").font(.title2.bold()).foregroundColor(.white)
            Text("Coming soon").foregroundColor(.amberSubtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.amberBG)
    }
}
