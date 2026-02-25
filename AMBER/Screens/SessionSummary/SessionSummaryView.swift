import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(hex: "121208").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("SESSION SUMMARY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.amberAccent)
                        .kerning(2)
                    Text("SESSION\nCOMPLETE")
                        .font(.system(size: 38, weight: .black).italic())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 36)
                .padding(.bottom, 28)

                // Level Ring
                ZStack {
                    Circle()
                        .stroke(Color.amberCard, lineWidth: 10)
                        .frame(width: 150, height: 150)
                    Circle()
                        .trim(from: 0, to: animate ? dataStore.levelProgress : 0)
                        .stroke(Color.amberAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.2), value: animate)
                    VStack(spacing: 4) {
                        Text("Level")
                            .font(.system(size: 14))
                            .foregroundColor(.amberSubtext)
                        Text("\(dataStore.level)")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.white)
                        Text("\(Int(dataStore.levelProgress * 100))% Complete")
                            .font(.system(size: 12))
                            .foregroundColor(.amberAccent)
                    }
                }
                .padding(.bottom, 28)

                // Score cards
                HStack(spacing: 12) {
                    SummaryCard(label: "TOTAL SCORE", value: "\(appState.lastSessionScore)")
                    SummaryCard(label: "XP GAINED", value: "+\(appState.lastSessionXP)", accent: true)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Tier progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gold Tier Progress")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(dataStore.xpToNextLevel) XP to Level \(dataStore.level + 1)")
                            .font(.system(size: 12))
                            .foregroundColor(.amberSubtext)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "2040A0").opacity(0.5))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.amberAccent)
                                .frame(width: geo.size.width * (animate ? dataStore.levelProgress : 0), height: 8)
                                .animation(.easeOut(duration: 1.2), value: animate)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        // Share stub
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberCard)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder, lineWidth: 1)))
                    }
                    Button {
                        appState.dismissSummary()
                    } label: {
                        HStack {
                            Text("CONTINUE")
                                .font(.system(size: 15, weight: .black))
                                .kerning(1.5)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberAccent))
                    }
                }
                .padding(.horizontal, 20)

                Text("🏅 New reward items unlocked in inventory")
                    .font(.system(size: 12))
                    .foregroundColor(.amberSubtext)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { animate = true } }
    }
}

struct SummaryCard: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(1)
            Text(value)
                .font(AMBERFont.mono(28, weight: .black))
                .foregroundColor(accent ? .amberAccent : .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amberCardBorder, lineWidth: 1))
        )
    }
}
