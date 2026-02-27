import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var name: String = ""

    var body: some View {
        ZStack {
            // Background
            RadialGradient(
                colors: [Color(hex: "3A1F0C"), Color(hex: "0D0A08")],
                center: .top, startRadius: 100, endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Nav Area
                HStack {
                    Button {
                        completeOnboarding()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "E06D24"))
                            .frame(width: 8, height: 8)
                        Text("AMBER")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .kerning(2)
                    }
                    .offset(x: -12) // visually center
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Glowing Emoji
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(hex: "E06D24").opacity(0.25), .clear],
                            center: .center, startRadius: 0, endRadius: 130
                        ))
                        .frame(width: 260, height: 260)

                    Circle()
                        .stroke(Color(hex: "E06D24").opacity(0.15), lineWidth: 1.5)
                        .frame(width: 210, height: 210)

                    Circle()
                        .stroke(Color(hex: "E06D24").opacity(0.3), lineWidth: 1.5)
                        .frame(width: 140, height: 140)

                    Text("😊")
                        .font(.system(size: 64))
                }
                .padding(.bottom, 24)

                // Headings
                Text("Welcome to AMBER")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text("High-end focus for your digital\njourney")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "D96826"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 60)

                // Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("IDENTIFY YOURSELF")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .kerning(1.2)

                    HStack {
                        TextField("Enter your name...", text: $name)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .medium))
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                        
                        Image(systemName: "touchid")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "F29661"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Start Button
                Button {
                    completeOnboarding()
                } label: {
                    HStack(spacing: 8) {
                        Text("Start Journey")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "ED752C"), Color(hex: "D95D1A")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func completeOnboarding() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            dataStore.userName = trimmed
            UserDefaults.standard.set(trimmed, forKey: "amber_userName")
        } else {
            UserDefaults.standard.set("Alex Storm", forKey: "amber_userName")
        }
        appState.showMoodCheckIn = true
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.showWelcome = false
        }
    }
}
