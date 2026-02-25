import AppIntents
import WidgetKit

// MARK: - Select Mood (State 1 → State 2)
struct SelectMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Mood"
    static var description = IntentDescription("Records the user's current mood.")

    @Parameter(title: "Mood Value")
    var mood: Int

    init() { mood = 1 }
    init(mood: Int) { self.mood = mood }

    func perform() async throws -> some IntentResult {
        let session = SharedStore.newSession(mood: mood)
        SharedStore.save(session)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Answer Stress Question (State 2/3 → outcome)
struct AnswerStressIntent: AppIntent {
    static var title: LocalizedStringResource = "Answer Stress Question"
    static var description = IntentDescription("Records a Yes/No stress answer.")

    @Parameter(title: "Answer")
    var answer: Bool

    init() { answer = false }
    init(answer: Bool) { self.answer = answer }

    func perform() async throws -> some IntentResult {
        guard var session = SharedStore.load() else { return .result() }
        if answer { session.yesCount += 1 }
        session.answeredCount += 1
        if session.isComplete {
            session.stressLevel = SharedStore.computeStressLevel(
                mood: session.primaryMood, yesCount: session.yesCount)
        }
        SharedStore.save(session)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
