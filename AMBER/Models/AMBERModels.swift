import SwiftUI
import Combine

// MARK: - Mood Type
enum MoodType: String, CaseIterable, Codable, Identifiable {
    case energized, okayish, low, overwhelmed
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .energized: return "😀"
        case .okayish:   return "😐"
        case .low:       return "😔"
        case .overwhelmed: return "🤯"
        }
    }
    var label: String {
        switch self {
        case .energized: return "Energized"
        case .okayish:   return "Okay-ish"
        case .low:       return "Low"
        case .overwhelmed: return "Overwhelmed"
        }
    }
    var suggestedGame: GameType {
        switch self {
        case .energized: return .flowGrid
        case .okayish:   return .focusArena
        case .low:       return .zenCanvas
        case .overwhelmed: return .zenCanvas
        }
    }
    var reactionMessage: String {
        switch self {
        case .energized: return "Let's challenge that brain! 🔥"
        case .okayish:   return "Let's find your flow. 🌟"
        case .low:       return "Alright, gentle mode activated 🌊"
        case .overwhelmed: return "Okay okay, we go slow. 💙"
        }
    }
}

// MARK: - Game Type
enum GameType: String, CaseIterable, Codable, Identifiable {
    case focusArena, flowGrid, zenCanvas
    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusArena: return "Focus Arena"
        case .flowGrid:   return "Flow Grid"
        case .zenCanvas:  return "Zen Canvas"
        }
    }
    var description: String {
        switch self {
        case .focusArena: return "Master your concentration in a high-stakes competitive environment."
        case .flowGrid:   return "Sync with the rhythmic patterns of professional cognitive efficiency."
        case .zenCanvas:  return "Decompress through fluid, generative artistry and reactive soundscapes."
        }
    }
    var statusText: String {
        switch self {
        case .focusArena: return "12 mins remaining"
        case .flowGrid:   return "Optimal flow detected"
        case .zenCanvas:  return "Session history: 4h"
        }
    }
    var buttonLabel: String {
        switch self {
        case .focusArena: return "Enter Arena"
        case .flowGrid:   return "Start Flow"
        case .zenCanvas:  return "Open Canvas"
        }
    }
    var systemIcon: String {
        switch self {
        case .focusArena: return "scope"
        case .flowGrid:   return "square.grid.2x2"
        case .zenCanvas:  return "paintpalette"
        }
    }
    var badge: String? {
        self == .focusArena ? "ELITE" : nil
    }
    var isPrimaryButton: Bool { self == .focusArena }
}

// MARK: - Tab
enum AMBERTab: CaseIterable {
    case home, stats, achievements, profile
    var icon: String {
        switch self {
        case .home:         return "house.fill"
        case .stats:        return "chart.bar.fill"
        case .achievements: return "trophy.fill"
        case .profile:      return "person.fill"
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var showMoodCheckIn: Bool
    @Published var selectedMood: MoodType? = nil
    @Published var activeGame: GameType? = nil
    @Published var showSessionSummary: Bool = false
    @Published var lastSessionScore: Int = 0
    @Published var lastSessionXP: Int = 0
    @Published var selectedTab: AMBERTab = .home

    init() {
        // Show mood check-in if not shown today
        let today = Calendar.current.startOfDay(for: Date())
        let lastCheckin = UserDefaults.standard.object(forKey: "amber_lastCheckin") as? Date
        if let last = lastCheckin, Calendar.current.startOfDay(for: last) == today {
            showMoodCheckIn = false
        } else {
            showMoodCheckIn = true
        }
    }

    func completeMoodCheckIn(mood: MoodType) {
        selectedMood = mood
        UserDefaults.standard.set(Date(), forKey: "amber_lastCheckin")
        withAnimation { showMoodCheckIn = false }
    }

    func startGame(_ game: GameType) { activeGame = game }

    func completeSession(score: Int, xp: Int) {
        lastSessionScore = score
        lastSessionXP   = xp
        activeGame      = nil
        showSessionSummary = true
    }

    func dismissSummary() { showSessionSummary = false }
}
