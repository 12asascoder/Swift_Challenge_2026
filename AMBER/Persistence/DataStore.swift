import Foundation

class DataStore: ObservableObject {
    @Published var xp: Int            { didSet { save("amber_xp", xp) } }
    @Published var level: Int         { didSet { save("amber_level", level) } }
    @Published var streak: Int        { didSet { save("amber_streak", streak) } }
    @Published var totalSessions: Int { didSet { save("amber_sessions", totalSessions) } }
    @Published var bestCombo: Int     { didSet { save("amber_bestCombo", bestCombo) } }
    @Published var lastSessionDate: Date?

    // Profile
    @Published var userName: String   { didSet { ud.set(userName, forKey: "amber_userName") } }
    @Published var bestFocusAccuracy: Double { didSet { ud.set(bestFocusAccuracy, forKey: "amber_bestAccuracy") } }
    @Published var bestFlowScore: Int { didSet { save("amber_bestFlowScore", bestFlowScore) } }
    var joinDate: Date

    // Reaction tracking
    private(set) var sumReactionMs: Double = 0
    private(set) var reactionCount: Int    = 0
    var avgReactionSeconds: Double { reactionCount > 0 ? sumReactionMs / Double(reactionCount) / 1000.0 : 0 }

    // Chart data
    @Published var moodTrend: [Double] = [0.2, 0.4, 0.35, 0.6, 0.55, 0.75, 0.9]

    private let ud = UserDefaults.standard
    private func save(_ key: String, _ val: Int) { ud.set(val, forKey: key) }
    private let thresholds = [0, 100, 250, 500, 1000, 2000, 4000, 7000, 11000, 16000, 22000]

    init() {
        xp               = ud.integer(forKey: "amber_xp")
        level            = max(1, ud.integer(forKey: "amber_level"))
        streak           = ud.integer(forKey: "amber_streak")
        totalSessions    = ud.integer(forKey: "amber_sessions")
        bestCombo        = ud.integer(forKey: "amber_bestCombo")
        bestFlowScore    = ud.integer(forKey: "amber_bestFlowScore")
        bestFocusAccuracy = ud.double(forKey: "amber_bestAccuracy")
        sumReactionMs    = ud.double(forKey:  "amber_sumReaction")
        reactionCount    = ud.integer(forKey: "amber_reactionCount")
        userName         = ud.string(forKey:  "amber_userName") ?? "Alex Storm"
        joinDate         = (ud.object(forKey: "amber_joinDate") as? Date) ?? Date()
        lastSessionDate  = ud.object(forKey: "amber_lastSession") as? Date

        if ud.object(forKey: "amber_joinDate") == nil {
            ud.set(Date(), forKey: "amber_joinDate")
        }
        if let data = ud.data(forKey: "amber_moodTrend"),
           let arr  = try? JSONDecoder().decode([Double].self, from: data) {
            moodTrend = arr
        }
        checkStreak()
    }

    func addSession(score: Int, xpGained: Int, combo: Int = 0, reactionMs: Double = 0, accuracy: Double = 0, flowScore: Int = 0) {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastSessionDate {
            let diff = Calendar.current.dateComponents([.day],
                from: Calendar.current.startOfDay(for: last), to: today).day ?? 0
            if diff == 1 { streak += 1 } else if diff > 1 { streak = 1 }
        } else { streak = 1 }

        ud.set(Date(), forKey: "amber_lastSession")
        lastSessionDate  = Date()
        xp              += xpGained
        totalSessions   += 1
        bestCombo        = max(bestCombo, combo)
        bestFocusAccuracy = max(bestFocusAccuracy, accuracy * 100)
        bestFlowScore    = max(bestFlowScore, flowScore)

        if reactionMs > 0 {
            sumReactionMs += reactionMs
            reactionCount += 1
            ud.set(sumReactionMs, forKey: "amber_sumReaction")
            ud.set(reactionCount, forKey: "amber_reactionCount")
        }

        let norm = min(1.0, Double(score) / 5000.0)
        moodTrend.append(norm)
        if moodTrend.count > 7 { moodTrend.removeFirst() }
        if let data = try? JSONEncoder().encode(moodTrend) { ud.set(data, forKey: "amber_moodTrend") }

        updateLevel()
    }

    private func updateLevel() {
        for (i, t) in thresholds.enumerated() where xp >= t { level = i + 1 }
    }

    private func checkStreak() {
        guard let last = lastSessionDate else { return }
        let diff = Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: last),
            to:   Calendar.current.startOfDay(for: Date())).day ?? 0
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

    var userTitle: String {
        switch level {
        case 1...3:   return "Amber Beginner"
        case 4...7:   return "Focus Seeker"
        case 8...12:  return "Zen Warrior"
        case 13...18: return "Flow Master"
        default:      return "Master of Zen"
        }
    }

    var tierName: String {
        switch level {
        case 1...5:   return "Bronze Tier"
        case 6...10:  return "Silver Tier"
        case 11...18: return "Gold Tier"
        default:      return "Platinum Tier"
        }
    }

    var tierXP: Int { xp }
    var tierMaxXP: Int { thresholds[min(level, thresholds.count - 1)] }

    var joinDateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return "Sprinting since \(f.string(from: joinDate))"
    }

    func resetAll() {
        let keys = ["amber_xp","amber_level","amber_streak","amber_sessions","amber_bestCombo",
                    "amber_bestFlowScore","amber_bestAccuracy","amber_sumReaction",
                    "amber_reactionCount","amber_lastSession","amber_moodTrend"]
        keys.forEach { ud.removeObject(forKey: $0) }
        xp = 0; level = 1; streak = 0; totalSessions = 0; bestCombo = 0
        bestFlowScore = 0; bestFocusAccuracy = 0; sumReactionMs = 0; reactionCount = 0
        moodTrend = [0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4]
    }

    static func xpFormula(baseScore: Int, difficulty: Double, streakBonus: Int) -> Int {
        Int(Double(baseScore) * difficulty) + streakBonus
    }
}
