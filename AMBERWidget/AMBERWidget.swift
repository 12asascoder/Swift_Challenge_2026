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

// MARK: - Medium Widget View
struct AMBERMoodWidgetView: View {
    let entry: MoodEntry

    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }
    private var bg:    Color { Color(red: 0.09, green: 0.08, blue: 0.05) }
    private var card:  Color { Color(red: 0.14, green: 0.12, blue: 0.07) }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning." }
        if h < 17 { return "Good afternoon." }
        return "Good evening."
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [bg, Color(red: 0.13, green: 0.11, blue: 0.07)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
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
            HStack(spacing: 12) {
                avatarCircle(icon: "person.fill", color: amber)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMBER ASSISTANT")
                        .font(.system(size: 9, weight: .semibold)).kerning(1.5).foregroundColor(amber)
                    Text(greeting)
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    Text("How's your vibe today?")
                        .font(.system(size: 13)).foregroundColor(amber)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12)
            Spacer(minLength: 6)
            HStack(spacing: 8) {
                moodBtn(emoji: "🙂", label: "Calm",    mood: 0)
                moodBtn(emoji: "😐", label: "Okay",    mood: 1)
                moodBtn(emoji: "😓", label: "Stressed", mood: 2)
            }
            .padding(.horizontal, 12)
            Spacer(minLength: 4)
            footer
        }
    }

    private func moodBtn(emoji: String, label: String, mood: Int) -> some View {
        Button(intent: SelectMoodIntent(mood: mood)) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 14))
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(Capsule().fill(card).overlay(Capsule().stroke(amber.opacity(0.55), lineWidth: 1)))
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
                Text("AMBER ASSISTANT")
                    .font(.system(size: 9, weight: .semibold)).kerning(1.5).foregroundColor(amber)
                Spacer()
                Text("Q\(qIdx + 1)/2").font(.system(size: 10)).foregroundColor(.gray)
            }
            Text(q)
                .font(.system(size: 16, weight: .medium)).foregroundColor(.white)
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
            HStack(spacing: 12) {
                avatarCircle(icon: icon, color: color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stateStr)
                        .font(.system(size: 9, weight: .bold)).kerning(2).foregroundColor(color)
                    Text(msg)
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12)
            Spacer()
            if level >= 1, let url = URL(string: link) {
                Link(destination: url) {
                    Text(btnLabel)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Capsule().fill(color))
                }
                .padding(.horizontal, 14).padding(.bottom, 10)
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

    // MARK: Shared subviews
    private func avatarCircle(icon: String, color: Color) -> some View {
        ZStack {
            Circle().stroke(color, lineWidth: 2.5).frame(width: 50, height: 50)
            Circle().fill(Color(red: 0.13, green: 0.11, blue: 0.07)).frame(width: 46, height: 46)
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
        }
    }

    private var footer: some View {
        HStack {
            Image(systemName: "chart.bar.fill").font(.system(size: 9)).foregroundColor(.gray)
            Text("7-DAY TREND: STABLE").font(.system(size: 9, weight: .semibold)).kerning(1).foregroundColor(.gray)
            Spacer()
            Text("AMBER").font(.system(size: 9, weight: .bold)).kerning(2).italic()
                .foregroundColor(amber.opacity(0.7))
        }
        .padding(.horizontal, 14).padding(.bottom, 8)
    }
}

// MARK: - Lock Screen Widget View
struct AMBERLockWidgetView: View {
    let entry: MoodEntry
    private var amber: Color { Color(red: 0.9, green: 0.65, blue: 0.1) }
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill").font(.system(size: 18)).foregroundColor(amber)
            Button(intent: SelectMoodIntent(mood: 0)) { Text("🙂").font(.system(size: 16)) }.buttonStyle(.plain)
            Button(intent: SelectMoodIntent(mood: 1)) { Text("😐").font(.system(size: 16)) }.buttonStyle(.plain)
            Button(intent: SelectMoodIntent(mood: 2)) { Text("😓").font(.system(size: 16)) }.buttonStyle(.plain)
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Medium Widget
struct AMBERMoodWidget: Widget {
    var kind: String { "AMBERMoodWidget" }
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
    var kind: String { "AMBERLockWidget" }
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
