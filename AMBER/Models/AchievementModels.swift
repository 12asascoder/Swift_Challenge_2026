import Foundation

// MARK: - Achievement model
enum AchievementCategory: String, CaseIterable {
    case all          = "All Badges"
    case mindfulness  = "Mindfulness"
    case focus        = "Focus"
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let systemIcon: String
    let category: AchievementCategory
    let targetValue: Int
    var currentValue: Int

    var progress: Double  { min(1.0, Double(currentValue) / Double(targetValue)) }
    var isCompleted: Bool { currentValue >= targetValue }
    var progressText: String {
        if isCompleted { return "Completed" }
        return "\(currentValue)/\(targetValue)"
    }
    var progressLabel: String {
        if isCompleted { return "Completed" }
        switch id {
        case "reactionKing": return "\(Int(progress * 100))%"
        case "nightOwl":     return "\(currentValue)/\(targetValue) Days"
        default:             return "\(currentValue)/\(targetValue)"
        }
    }
}

extension DataStore {
    static func buildAchievements(from ds: DataStore) -> [Achievement] {
        [
            Achievement(id: "flowMaster",    title: "Flow Master",    description: "Maintain focus for 60 mins", systemIcon: "water.waves",         category: .focus,        targetValue: 5,  currentValue: min(5, ds.totalSessions)),
            Achievement(id: "reactionKing",  title: "Reaction King",  description: "Under 200ms response",      systemIcon: "bolt.fill",            category: .focus,        targetValue: 1,  currentValue: ds.avgReactionSeconds < 0.2 && ds.avgReactionSeconds > 0 ? 1 : 0),
            Achievement(id: "sevenDayZen",   title: "7-Day Zen",      description: "Weekly meditation streak",  systemIcon: "figure.mind.and.body", category: .mindfulness,  targetValue: 7,  currentValue: min(7, ds.streak)),
            Achievement(id: "nightOwl",      title: "Night Owl",      description: "Mindfulness after 10 PM",   systemIcon: "moon.fill",            category: .mindfulness,  targetValue: 10, currentValue: min(10, ds.totalSessions / 3)),
            Achievement(id: "calmPulse",     title: "Calm Pulse",     description: "HRV recovery session",      systemIcon: "waveform.path.ecg",    category: .mindfulness,  targetValue: 10, currentValue: min(10, ds.totalSessions)),
            Achievement(id: "breathGuru",    title: "Breath Guru",    description: "50 breathing cycles",       systemIcon: "wind",                 category: .mindfulness,  targetValue: 50, currentValue: min(50, ds.totalSessions * 5)),
        ]
    }

    var completedCount: Int { DataStore.buildAchievements(from: self).filter { $0.isCompleted }.count }
}
