import SwiftUI

struct AvatarMoodCheckInView: View {
    @EnvironmentObject var appState: AppState
    @State private var bounce  = false
    @State private var selectedMood: MoodType? = nil
    @State private var reacting = false
    @State private var dialogueIndex = 0

    private let dialogues = [
        "Hey superstar ✨ How's your vibe today?",
        "Brain feeling spicy 🌶 or sleepy 💤?",
        "Mood check! Are we glowing or grumbling?",
        "Energy level: Hero mode or potato mode?"
    ]

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()
            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button { appState.completeMoodCheckIn(mood: .okayish) } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("AMBER AI")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.amberAccent)
                            .kerning(1.5)
                        Text("Daily Check-in")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.amberSubtext)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Speech bubble
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.amberAccent)
                        .frame(maxWidth: .infinity)
                    Text(dialogues[dialogueIndex])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(18)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .onTapGesture {
                    withAnimation { dialogueIndex = (dialogueIndex + 1) % dialogues.count }
                }

                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "A8D8EA"))
                        .frame(width: 200, height: 180)
                    Text("😊")
                        .font(.system(size: 110))
                        .scaleEffect(bounce ? 1.08 : 1.0)
                        .scaleEffect(reacting ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: bounce)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: reacting)
                }
                .padding(.vertical, 20)
                .onAppear { bounce = true }

                // Vibe label
                Text("SELECT YOUR VIBE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.amberAccent)
                    .kerning(2)
                    .padding(.bottom, 12)

                // Mood grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MoodType.allCases) { mood in
                        MoodButtonView(mood: mood, isSelected: selectedMood == mood) {
                            withAnimation(.spring()) {
                                selectedMood = mood
                                reacting = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                reacting = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                appState.completeMoodCheckIn(mood: mood)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                Spacer(minLength: 20)
            }
        }
    }
}

struct MoodButtonView: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(mood.emoji)
                    .font(.system(size: 36))
                Text(mood.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.amberAccent.opacity(0.2) : Color.amberCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.amberAccent : Color.amberCardBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}
