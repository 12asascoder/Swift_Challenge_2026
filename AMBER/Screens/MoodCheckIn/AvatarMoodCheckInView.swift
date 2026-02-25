import SwiftUI

struct AvatarMoodCheckInView: View {
    @EnvironmentObject var appState: AppState
    @State private var bounce        = false
    @State private var selectedMood: MoodType? = nil
    @State private var reacting      = false
    @State private var dialogueIndex = 0

    private let dialogues = [
        "Hey superstar ✨ How's your\nvibe today?",
        "Brain feeling spicy 🌶 or sleepy 💤?",
        "Mood check! Glowing or grumbling?",
        "Energy level: Hero mode or potato mode?"
    ]

    // Emoji that reacts to selected mood
    private var moodEmoji: String {
        switch selectedMood {
        case .energized:   return "😁"
        case .okayish:     return "😊"
        case .low:         return "😔"
        case .overwhelmed: return "🤯"
        case nil:          return "😊"
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0F0E0A").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                // Greeting card (amber bg, dark text)
                greetingCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // 3D emoji preview box
                emojiBox
                    .padding(.top, 18)

                // SELECT YOUR VIBE label
                Text("SELECT YOUR VIBE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.amberAccent)
                    .kerning(2.5)
                    .padding(.top, 22)
                    .padding(.bottom, 14)

                // 2 × 2 mood grid
                moodGrid
                    .padding(.horizontal, 20)

                Spacer(minLength: 16)

                // Bottom tab bar mimic (cosmetic, matches design reference)
                bottomBar
            }
        }
        .onAppear { bounce = true; AudioManager.shared.playBackground() }

    }

    // MARK: - Nav bar
    private var navBar: some View {
        HStack {
            Button {
                appState.completeMoodCheckIn(mood: .okayish)
            } label: {
                ZStack {
                    Circle().stroke(Color.amberAccent.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.amberAccent)
                }
            }
            Spacer()
            VStack(spacing: 1) {
                Text("AMBER AI")
                    .font(.system(size: 10, weight: .bold)).kerning(2)
                    .foregroundColor(.amberAccent)
                Text("Daily Check-in")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            ZStack {
                Circle().stroke(Color.amberAccent.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.amberAccent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Greeting card
    private var greetingCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "E8A020"))
            Text(dialogues[dialogueIndex])
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "1A1200"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                dialogueIndex = (dialogueIndex + 1) % dialogues.count
            }
        }
    }

    // MARK: - Emoji preview box
    private var emojiBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "87CEDC"))
                .frame(width: 220, height: 195)
            Text(moodEmoji)
                .font(.system(size: 120))
                .scaleEffect(bounce   ? 1.06 : 1.0)
                .scaleEffect(reacting ? 1.25 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bounce)
                .animation(.spring(response: 0.3, dampingFraction: 0.45), value: reacting)
        }
    }

    // MARK: - 2×2 Mood grid
    private var moodGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(MoodType.allCases) { mood in
                MoodButtonView(mood: mood, isSelected: selectedMood == mood) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        selectedMood = mood
                        reacting     = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { reacting = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                        appState.completeMoodCheckIn(mood: mood)
                    }
                }
            }
        }
    }

    // MARK: - Cosmetic bottom tab bar
    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill",   label: "HOME",     active: false)
            tabItem(icon: "sparkles",     label: "MOOD",     active: false)
            // Centre FAB
            ZStack {
                Circle().fill(Color.amberAccent).frame(width: 54, height: 54)
                    .shadow(color: Color.amberAccent.opacity(0.5), radius: 8)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            tabItem(icon: "chart.bar.fill", label: "INSIGHTS", active: false)
            tabItem(icon: "person.fill",    label: "PROFILE",  active: false)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 20)
        .padding(.top, 8)
        .background(Color(hex: "141209"))
    }

    private func tabItem(icon: String, label: String, active: Bool) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .foregroundColor(active ? .amberAccent : Color.gray.opacity(0.7))
            Text(label)
                .font(.system(size: 8, weight: .semibold)).kerning(0.5)
                .foregroundColor(active ? .amberAccent : Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mood button card
struct MoodButtonView: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(mood.emoji).font(.system(size: 38))
                Text(mood.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .amberAccent : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: isSelected ? "2A1F08" : "1C1A12"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.amberAccent : Color.amberCardBorder.opacity(0.6),
                                    lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
