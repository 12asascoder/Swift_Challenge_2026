import SwiftUI

struct HomeHubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore

    var stateLabel: String {
        switch appState.selectedMood {
        case .energized:   return "ENERGIZED"
        case .okayish:     return "BALANCED"
        case .low:         return "RESTING"
        case .overwhelmed: return "RECOVERING"
        default:           return "BALANCED"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.amberBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .foregroundColor(.amberAccent)
                                .font(.system(size: 20))
                            Text("AMBER")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.amberSubtext)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATE: \(stateLabel)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.amberAccent)
                            .kerning(1.5)
                        Text("Home Hub")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // Game cards
                    VStack(spacing: 14) {
                        ForEach(GameType.allCases) { game in
                            GameCardView(game: game) {
                                AudioManager.shared.fadeOut(duration: 1.0)
                                appState.startGame(game)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Streak
                    StreakBadge(streak: dataStore.streak)
                        .padding(.top, 24)
                        .padding(.bottom, 100) // room for tab bar
                }
            }
        }
        .onAppear { AudioManager.shared.ensurePlaying() }
    }
}
