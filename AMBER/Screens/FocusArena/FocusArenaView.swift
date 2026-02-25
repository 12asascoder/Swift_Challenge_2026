import SwiftUI

struct FocusArenaView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var vm = FocusArenaViewModel()
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()

            // Orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FF8C00"), Color(hex: "CC5500").opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                if vm.isFlashing {
                    Circle()
                        .stroke(Color.amberAccent, lineWidth: 3)
                        .frame(width: 210, height: 210)
                        .transition(.opacity)
                }
                // Ripple
                Circle()
                    .stroke(Color.amberAccent.opacity(rippleOpacity), lineWidth: 2)
                    .frame(width: 200 * rippleScale, height: 200 * rippleScale)
            }
            .offset(y: vm.orbY - 120)
            .onTapGesture { onOrbTap() }
            .animation(.easeInOut(duration: 0.3), value: vm.isFlashing)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { appState.activeGame = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("FOCUS ARENA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.amberAccent)
                            .kerning(2)
                        Text("\(vm.score)")
                            .font(AMBERFont.mono(32, weight: .black))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(Color.amberAccent).frame(width: 36, height: 36)
                        Text("AM")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                HStack {
                    Text("LEVEL \(dataStore.level)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.amberSubtext)
                        .kerning(1)
                    Spacer()
                    Text("\(vm.timeLeft)s")
                        .font(AMBERFont.mono(14, weight: .bold))
                        .foregroundColor(vm.timeLeft <= 10 ? .red : .amberSubtext)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                Spacer()

                // Bottom panel
                VStack(spacing: 16) {
                    // Sync bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("FOCUS SYNCHRONIZATION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.amberAccent)
                                .kerning(1.5)
                            Spacer()
                            Text("\(Int(vm.syncPercent * 100))%")
                                .font(AMBERFont.mono(13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.amberButtonOlive).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4).fill(Color.amberAccent)
                                    .frame(width: geo.size.width * vm.syncPercent, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.amberCard))

                    // Stats cards
                    HStack(spacing: 12) {
                        StatCard(
                            label: "MULTIPLIER",
                            value: "x\(String(format: "%.1f", vm.multiplier))",
                            delta: "+0.5",
                            deltaColor: .green,
                            borderColor: .amberAccent
                        )
                        StatCard(
                            label: "REACTION",
                            value: vm.reactionMs > 0 ? "\(vm.reactionMs)ms" : "--",
                            delta: vm.reactionMs > 0 ? "-\(max(0, vm.reactionMs - 180))ms" : "",
                            deltaColor: .red,
                            borderColor: Color(hex: "00C8CC")
                        )
                    }

                    // Play button
                    if !vm.isRunning {
                        Button { vm.startSession() } label: {
                            ZStack {
                                Circle().fill(Color.amberAccent).frame(width: 64, height: 64)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .onChange(of: vm.sessionEnded) { ended in
            if ended {
                dataStore.addSession(score: vm.score, xpGained: vm.calculatedXP)
                appState.completeSession(score: vm.score, xp: vm.calculatedXP)
            }
        }
    }

    private func onOrbTap() {
        vm.tap()
        rippleScale = 0.5
        rippleOpacity = 0.8
        withAnimation(.easeOut(duration: 0.6)) {
            rippleScale = 2.0
            rippleOpacity = 0
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: String
    let delta: String
    let deltaColor: Color
    let borderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(1)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(AMBERFont.mono(24, weight: .black))
                    .foregroundColor(.white)
                if !delta.isEmpty {
                    Text(delta)
                        .font(AMBERFont.mono(12, weight: .bold))
                        .foregroundColor(deltaColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.amberCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor.opacity(0.6), lineWidth: 1.5))
        )
    }
}
