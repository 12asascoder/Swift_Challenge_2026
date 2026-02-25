import Foundation

// MARK: - App Group
public let amberAppGroupID = "group.com.amber.app"

// MARK: - Stress Questions
public let stressQuestions: [String] = [
    "Is your mind racing today?",
    "Finding it hard to focus?",
    "Feeling mentally cluttered?",
    "Low energy?",
    "Are small things irritating you?"
]

// MARK: - Widget State
public enum WidgetState: Int, Codable {
    case moodPrompt, stressQ1, stressQ2, outcome
}

// MARK: - MoodSession
public struct MoodSession: Codable {
    public var primaryMood: Int       // 0=Calm, 1=Okay, 2=Stressed
    public var yesCount: Int
    public var stressLevel: Int       // 0=Stable, 1=Moderate, 2=High
    public var date: Date
    public var questionIndices: [Int] // 2 shuffled indices from stressQuestions
    public var answeredCount: Int     // 0, 1, or 2

    public var isComplete: Bool { answeredCount >= 2 }

    public var widgetState: WidgetState {
        if isComplete      { return .outcome  }
        if answeredCount == 1 { return .stressQ2 }
        return .stressQ1
    }

    public init(primaryMood: Int, yesCount: Int, stressLevel: Int,
                date: Date, questionIndices: [Int], answeredCount: Int) {
        self.primaryMood     = primaryMood
        self.yesCount        = yesCount
        self.stressLevel     = stressLevel
        self.date            = date
        self.questionIndices = questionIndices
        self.answeredCount   = answeredCount
    }
}

// MARK: - Shared Store
public struct SharedStore {
    private static var defaults: UserDefaults? { UserDefaults(suiteName: amberAppGroupID) }
    private static let sessionKey = "amber_widget_moodSession"

    public static func load() -> MoodSession? {
        guard let data    = defaults?.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(MoodSession.self, from: data)
        else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        guard Calendar.current.startOfDay(for: session.date) == today else { return nil }
        return session
    }

    public static func save(_ session: MoodSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults?.set(data, forKey: sessionKey)
    }

    public static func currentWidgetState() -> WidgetState {
        guard let session = load() else { return .moodPrompt }
        return session.widgetState
    }

    public static func newSession(mood: Int) -> MoodSession {
        let indices = Array((0..<stressQuestions.count).shuffled().prefix(2))
        return MoodSession(primaryMood: mood, yesCount: 0, stressLevel: 0,
                           date: Date(), questionIndices: indices, answeredCount: 0)
    }

    public static func computeStressLevel(mood: Int, yesCount: Int) -> Int {
        let score = mood + yesCount
        if score <= 1 { return 0 }   // Stable
        if score == 2 { return 1 }   // Moderate
        return 2                      // High
    }
}
