import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showRing = false

    // Passed in from AppState via complete
    private var grade: String {
        let pct = Double(appState.lastSessionScore) / 3000.0
        if pct >= 0.85 { return "A+" }
        if pct >= 0.7  { return "A"  }
        if pct >= 0.55 { return "B"  }
        if pct >= 0.4  { return "C"  }
        return "D"
    }
    private var ratingLabel: String {
        switch grade {
        case "A+", "A": return "Excellent performance!"
        case "B":       return "Great focus!"
        case "C":       return "Keep improving!"
        default:        return "Keep practicing!"
        }
    }
    private var isTopGrade: Bool { grade == "A+" || grade == "A" }

    var body: some View {
        ZStack {
            Color(hex: "0D0D0A").ignoresSafeArea()
            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button { appState.dismissSummary() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Session Complete")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { } label: {
                        Text("Share")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.amberAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Grade ring
                ZStack {
                    Circle()
                        .stroke(Color.amberCard, lineWidth: 5)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: showRing ? dataStore.levelProgress : 0)
                        .stroke(Color.amberAccent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.2), value: showRing)
                    Text(grade)
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(.amberAccent)
                }
                .padding(.bottom, 16)

                Text("Focus Rating")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(ratingLabel)
                    .font(.system(size: 14))
                    .foregroundColor(.amberSubtext)
                    .padding(.top, 4)
                    .padding(.bottom, 28)

                // Combo + Reaction cards
                HStack(spacing: 12) {
                    SummaryStatCard(
                        icon: "bolt.fill",
                        label: "Best Combo",
                        value: "\(dataStore.bestCombo)"
                    )
                    SummaryStatCard(
                        icon: "timer",
                        label: "Avg. Reaction",
                        value: String(format: "%.2fs", dataStore.avgReactionSeconds)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // XP card
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.amberCard)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.amberCardBorder, lineWidth: 1))
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.amberSubtext)
                                Text("XP Earned")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.amberSubtext)
                            }
                            Text("+\(appState.lastSessionXP)")
                                .font(AMBERFont.mono(32, weight: .black))
                                .foregroundColor(.amberAccent)
                        }
                        Spacer()
                        // Bar chart decoration
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach([0.4, 0.6, 0.75, 1.0], id: \.self) { h in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.amberAccent.opacity(0.6 + h * 0.4))
                                    .frame(width: 14, height: 55 * h)
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(height: 100)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        appState.dismissSummary()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            appState.startGame(.focusArena)
                        }
                    } label: {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberAccent))
                    }
                    Button { appState.dismissSummary(); appState.selectedTab = .stats } label: {
                        Text("Review Stats")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.amberCard)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder, lineWidth: 1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showRing = true } }
    }
}

struct SummaryStatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.amberSubtext)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.amberSubtext)
            }
            Text(value)
                .font(AMBERFont.mono(30, weight: .black))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color.amberCard)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.amberCardBorder, lineWidth: 1)))
    }
}
