import Foundation

class DataStore: ObservableObject {
    @Published var xp: Int       { didSet { save("amber_xp", xp) } }
    @Published var level: Int    { didSet { save("amber_level", level) } }
    @Published var streak: Int   { didSet { save("amber_streak", streak) } }
    @Published var totalSessions: Int { didSet { save("amber_sessions", totalSessions) } }
    @Published var lastSessionDate: Date?

    private let ud = UserDefaults.standard
    private func save(_ key: String, _ val: Int) { ud.set(val, forKey: key) }

    // XP thresholds per level
    private let thresholds = [0, 100, 250, 500, 1000, 2000, 4000, 7000, 11000, 16000, 22000]

    init() {
        xp            = ud.integer(forKey: "amber_xp")
        level         = max(1, ud.integer(forKey: "amber_level"))
        streak        = ud.integer(forKey: "amber_streak")
        totalSessions = ud.integer(forKey: "amber_sessions")
        lastSessionDate = ud.object(forKey: "amber_lastSession") as? Date
        checkStreak()
    }

    func addSession(score: Int, xpGained: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastSessionDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 { streak += 1 }
            else if diff > 1 { streak = 1 }
        } else {
            streak = 1
        }
        ud.set(Date(), forKey: "amber_lastSession")
        lastSessionDate = Date()
        xp += xpGained
        totalSessions += 1
        updateLevel()
    }

    private func updateLevel() {
        for (i, threshold) in thresholds.enumerated() where xp >= threshold {
            level = i + 1
        }
    }

    private func checkStreak() {
        guard let last = lastSessionDate else { return }
        let diff = Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: last),
            to: Calendar.current.startOfDay(for: Date())).day ?? 0
        if diff > 1 { streak = 0 }
    }

    var levelProgress: Double {
        let cur  = thresholds[min(level - 1, thresholds.count - 1)]
        let next = thresholds[min(level,     thresholds.count - 1)]
        guard next > cur else { return 1.0 }
        return min(max(Double(xp - cur) / Double(next - cur), 0), 1)
    }

    var xpToNextLevel: Int {
        let next = thresholds[min(level, thresholds.count - 1)]
        return max(0, next - xp)
    }

    static func xpFormula(baseScore: Int, difficulty: Double, streakBonus: Int) -> Int {
        Int(Double(baseScore) * difficulty) + streakBonus
    }
}
