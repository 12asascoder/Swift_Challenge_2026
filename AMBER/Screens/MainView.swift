import SwiftUI

// MARK: - Main Layout
struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore

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
            case .focusArena: FocusArenaView()
            case .flowGrid:   FlowGridView()
            case .zenCanvas:  ZenCanvasView()
            }
        }
        .sheet(isPresented: $appState.showSessionSummary) {
            SessionSummaryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
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
