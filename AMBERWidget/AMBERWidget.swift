import WidgetKit
import SwiftUI

// MARK: - Timeline entry
struct MoodEntry: TimelineEntry {
    let date: Date
    let session: MoodSession?
    let state: WidgetState
}

// MARK: - Provider
struct MoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), session: nil, state: .moodPrompt)
    }
    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        completion(MoodEntry(date: Date(), session: SharedStore.load(), state: SharedStore.currentWidgetState()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let entry    = MoodEntry(date: Date(), session: SharedStore.load(), state: SharedStore.currentWidgetState())
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Medium Widget View (Home Screen — matches Image 2)
struct AMBERMoodWidgetView: View {
    let entry: MoodEntry

    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }
    private var bg:    Color { Color(red: 0.11, green: 0.10, blue: 0.07) }
    private var card:  Color { Color(red: 0.17, green: 0.15, blue: 0.09) }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ZStack {
            bg
            switch entry.state {
            case .moodPrompt: moodPromptView
            case .stressQ1:   stressView(qIdx: 0)
            case .stressQ2:   stressView(qIdx: 1)
            case .outcome:    outcomeView
            }
        }
        .containerBackground(bg, for: .widget)
    }

    // MARK: State 1 — Mood Prompt
    private var moodPromptView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: greeting + amber "A" avatar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(greeting)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                    Text("How are you feeling?")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                Spacer()
                ZStack {
                    Circle().fill(amber).frame(width: 34, height: 34)
                    Text("A")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            Spacer()

            // 4 emoji mood buttons in a row
            HStack(spacing: 6) {
                moodBtn(emoji: "😞", mood: 0)
                moodBtn(emoji: "😐", mood: 1)
                moodBtn(emoji: "🙂", mood: 2)
                moodBtn(emoji: "😁", mood: 3)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
    }

    private func moodBtn(emoji: String, mood: Int) -> some View {
        let isSelected = entry.session?.primaryMood == mood
        return Button(intent: SelectMoodIntent(mood: mood)) {
            Text(emoji)
                .font(.system(size: isSelected ? 24 : 18))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? amber.opacity(0.22) : card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? amber : Color.white.opacity(0.07),
                                        lineWidth: isSelected ? 1.5 : 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: State 2/3 — Stress Question
    private func stressView(qIdx: Int) -> some View {
        let session = entry.session
        let idx     = session?.questionIndices[safe: qIdx] ?? qIdx
        let q       = stressQuestions[safe: idx] ?? stressQuestions[0]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AMBER")
                    .font(.system(size: 9, weight: .bold)).kerning(1.5).foregroundColor(amber)
                Spacer()
                Text("Q\(qIdx + 1)/2").font(.system(size: 10)).foregroundColor(.gray)
            }
            Text(q)
                .font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack(spacing: 10) {
                answerBtn("Yes", answer: true,  fill: amber.opacity(0.25), border: amber)
                answerBtn("No",  answer: false, fill: card,                border: Color.gray.opacity(0.4))
            }
        }
        .padding(14)
    }

    private func answerBtn(_ label: String, answer: Bool, fill: Color, border: Color) -> some View {
        Button(intent: AnswerStressIntent(answer: answer)) {
            Text(label)
                .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(Capsule().fill(fill).overlay(Capsule().stroke(border, lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }

    // MARK: State 4 — Outcome
    private var outcomeView: some View {
        let level     = entry.session?.stressLevel ?? 0
        let icon      = level == 0 ? "leaf.fill"  : level == 1 ? "wind"    : "bolt.fill"
        let color     = level == 0 ? Color.green  : level == 1 ? amber     : Color.orange
        let stateStr  = level == 0 ? "STABLE"     : level == 1 ? "MODERATE": "HIGH STRESS"
        let msg       = level == 0 ? "Nice. Keep flowing."
                      : level == 1 ? "Quick sync session?"
                      : "Let's recalibrate."
        let link      = level >= 2 ? "amber://focus" : "amber://flow"
        let btnLabel  = level >= 2 ? "Enter Focus Arena" : "Start Flow"

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(color, lineWidth: 2).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(stateStr)
                        .font(.system(size: 9, weight: .bold)).kerning(2).foregroundColor(color)
                    Text(msg)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14)
            Spacer()
            if level >= 1, let url = URL(string: link) {
                Link(destination: url) {
                    Text(btnLabel)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(Capsule().fill(color))
                }
                .padding(.horizontal, 14).padding(.bottom, 12)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 12))
                    Text("You're doing great today.").font(.system(size: 12)).foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Lock Screen Widget View (matches Image 1)
struct AMBERLockWidgetView: View {
    let entry: MoodEntry
    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }
    private var bg:    Color { Color(red: 0.09, green: 0.08, blue: 0.05) }
    private var card:  Color { Color(red: 0.16, green: 0.14, blue: 0.08) }

    private var lastUpdatedText: String {
        guard let session = entry.session else { return "LAST UPDATED: JUST NOW" }
        let mins = Int(-session.date.timeIntervalSinceNow / 60)
        if mins < 1  { return "LAST UPDATED: JUST NOW" }
        if mins < 60 { return "LAST UPDATED: \(mins)M AGO" }
        return "LAST UPDATED: \(mins / 60)H AGO"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: person icon + "AMBER" + amber dot
            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(amber.opacity(0.22)).frame(width: 22, height: 22)
                    Image(systemName: "person.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(amber)
                }
                Text("AMBER")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .kerning(1)
                Spacer()
                Circle().fill(amber).frame(width: 6, height: 6)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)

            // Row 2: CURRENT MOOD label
            Text("CURRENT MOOD")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
                .kerning(1.8)
                .padding(.horizontal, 10)
                .padding(.top, 4)

            // Row 3: 3 emoji buttons
            HStack(spacing: 5) {
                lockMoodBtn(emoji: "🙂", mood: 0)
                lockMoodBtn(emoji: "😐", mood: 1)
                lockMoodBtn(emoji: "😟", mood: 2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)

            Spacer(minLength: 2)

            // Row 4: Last updated footer
            Text(lastUpdatedText)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.28))
                .kerning(0.8)
                .padding(.horizontal, 10)
                .padding(.bottom, 7)
        }
        .background(bg)
        .containerBackground(bg, for: .widget)
    }

    private func lockMoodBtn(emoji: String, mood: Int) -> some View {
        let isSelected = entry.session?.primaryMood == mood
        return Button(intent: SelectMoodIntent(mood: mood)) {
            Text(emoji)
                .font(.system(size: isSelected ? 20 : 16))
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? amber.opacity(0.28) : card)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? amber : Color.white.opacity(0.07),
                                    lineWidth: isSelected ? 1.5 : 0.5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Medium Widget
struct AMBERMoodWidget: Widget {
    let kind: String = "AMBERMoodWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            AMBERMoodWidgetView(entry: entry)
        }
        .configurationDisplayName("AMBER Mood")
        .description("Check in with your cognitive companion.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Lock Screen Widget
struct AMBERLockWidget: Widget {
    let kind: String = "AMBERLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            AMBERLockWidgetView(entry: entry)
        }
        .configurationDisplayName("AMBER Mood")
        .description("Quick mood check.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Safe array subscript
extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
