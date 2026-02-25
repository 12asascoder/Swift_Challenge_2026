import SwiftUI

struct FocusArenaView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var vm = FocusArenaViewModel()
    @State private var rippleActive = false
    @State private var ripplePos: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(hex: "0A0A08").ignoresSafeArea()

                // Flow Mode glow overlay
                if vm.isFlowMode {
                    RadialGradient(colors: [Color.amberAccent.opacity(0.12), Color.clear],
                                   center: .center, startRadius: 0, endRadius: 400)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.5), value: vm.isFlowMode)
                }

                VStack(spacing: 0) {
                    headerBar
                    flowModeBanner
                    Spacer()
                }

                // Energy Core (moves freely over canvas)
                EnergyCore(
                    size:       vm.coreSize,
                    isFlow:     vm.isFlowMode,
                    isShrink:   vm.isShrinkMode,
                    phase:      vm.currentPhase
                )
                .position(vm.corePosition)
                .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: vm.corePosition)

                // TAP TARGET label (below core)
                if !vm.isFlowMode && !vm.isRunning {
                    VStack {
                        Spacer().frame(height: geo.size.height * 0.62)
                        Text("TAP TO START")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.amberSubtext)
                            .kerning(3)
                        Spacer()
                    }
                }

                // Hit feedback label
                if vm.showHitFeedback, let hit = vm.lastHit {
                    hitFeedbackLabel(hit)
                }

                // Ripple
                if rippleActive {
                    Circle()
                        .stroke(Color.amberAccent.opacity(0.5), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(rippleActive ? 2 : 0.5)
                        .opacity(rippleActive ? 0 : 0.8)
                        .position(ripplePos)
                        .animation(.easeOut(duration: 0.5), value: rippleActive)
                }

                VStack(spacing: 0) {
                    Spacer()
                    bottomPanel(geo: geo)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { val in
                handleTap(at: val.startLocation, geo: geo)
            })
            .onAppear { vm.bounds = geo.size }
            .onChange(of: geo.size) { vm.bounds = $0 }
        }
        .onChange(of: vm.sessionEnded) { ended in
            if ended {
                dataStore.addSession(score: vm.score, xpGained: vm.calculatedXP,
                                     combo: vm.bestCombo, reactionMs: vm.avgReactionSeconds * 1000)
                appState.completeSession(score: vm.score, xp: vm.calculatedXP)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Sub-views
    private var headerBar: some View {
        HStack(alignment: .center) {
            Button { appState.activeGame = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.amberCard))
            }
            Spacer()
            VStack(spacing: 2) {
                if vm.isFlowMode {
                    Text("FLOW MODE ACTIVE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.amberAccent)
                        .kerning(1.5)
                } else {
                    Text("FOCUS ARENA")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.amberSubtext)
                        .kerning(2)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                // Time
                VStack(spacing: 1) {
                    Text("TIME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.amberSubtext)
                        .kerning(1)
                    Text(String(format: "00:%02d", vm.timeLeft))
                        .font(AMBERFont.mono(14, weight: .black))
                        .foregroundColor(.white)
                }
                // Combo circle
                ZStack {
                    Circle()
                        .stroke(Color.amberAccent, lineWidth: 2)
                        .frame(width: 34, height: 34)
                    Text("\(vm.combo)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.amberAccent)
                }
                // XP x2 badge in flow
                if vm.isFlowMode {
                    Text("XP x2")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.amberAccent))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var flowModeBanner: some View {
        if vm.isFlowMode {
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("SYNCED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.amberSubtext)
            }
            .padding(.bottom, 4)
        }
    }

    private func hitFeedbackLabel(_ hit: HitQuality) -> some View {
        Text(hit.rawValue)
            .font(.system(size: 20, weight: .black))
            .foregroundColor(hit.color)
            .shadow(color: hit.color.opacity(0.8), radius: 8)
            .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                    removal: .opacity))
    }

    private func bottomPanel(geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Focus sync
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("FOCUS SYNC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.amberSubtext)
                        .kerning(1.5)
                    Spacer()
                    Text("\(Int(vm.syncPercent * 100))%")
                        .font(AMBERFont.mono(13, weight: .black))
                        .foregroundColor(vm.isFlowMode ? .amberAccent : .white)
                }
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "252518")).frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(vm.isFlowMode ?
                                  LinearGradient(colors: [.cyan, .amberAccent], startPoint: .leading, endPoint: .trailing) :
                                  LinearGradient(colors: [.amberAccentDim, .amberAccent], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: bar.size.width * vm.syncPercent, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: vm.syncPercent)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)

            // Stat cards row
            HStack(spacing: 8) {
                MiniStatCard(label: "MULTIPLIER", value: "x\(String(format: "%.1f", vm.multiplier))", accent: true)
                MiniStatCard(label: "BEST COMBO", value: "\(vm.bestCombo)")
                MiniStatCard(label: "REACTION",   value: vm.lastReactionMs > 0 ? String(format: "%.2fs", vm.lastReactionMs/1000) : "--")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 34)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "111108"))
                .overlay(RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.amberCardBorder.opacity(0.5), lineWidth: 1))
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.horizontal, 0)
    }

    // MARK: - Tap handler
    private func handleTap(at point: CGPoint, geo: GeometryProxy) {
        if !vm.isRunning {
            vm.bounds = geo.size
            vm.start(); return
        }
        vm.tap(at: point)
        ripplePos = point
        rippleActive = false
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.5)) { self.rippleActive = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.rippleActive = false }
        }
    }
}

// MARK: - Energy Core
struct EnergyCore: View {
    let size: CGFloat
    let isFlow: Bool
    let isShrink: Bool
    let phase: MovementPhase
    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            // Outermost faint ring
            Circle()
                .stroke(Color.amberAccent.opacity(0.06), lineWidth: 1)
                .frame(width: size * 2.8, height: size * 2.8)
            // Second ring
            Circle()
                .stroke(Color.amberAccent.opacity(isFlow ? 0.25 : 0.12), lineWidth: 1)
                .frame(width: size * 2.0, height: size * 2.0)
            // Glow bloom
            Circle()
                .fill(RadialGradient(
                    colors: [isFlow ? Color.amberAccent.opacity(0.3) : Color.amberAccent.opacity(0.15), .clear],
                    center: .center, startRadius: 0, endRadius: size * 0.8))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 10)
            // Rotating arc ring
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(AngularGradient(colors: [Color.amberAccent.opacity(0.7), .clear],
                                        center: .center), lineWidth: 2)
                .frame(width: size * 1.12, height: size * 1.12)
                .rotationEffect(.degrees(rotation))
            // Main amber core
            Circle()
                .fill(RadialGradient(
                    colors: isFlow
                        ? [Color(hex: "FFFFFF"), Color(hex: "FFD060"), Color(hex: "CC6600")]
                        : [Color(hex: "FFD060"), Color(hex: "F5A623"), Color(hex: "AA5500")],
                    center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
                .frame(width: size, height: size)
                .shadow(color: Color.amberAccent.opacity(0.7), radius: 20)
                .shadow(color: Color.amberAccent.opacity(0.3), radius: 40)
                .scaleEffect(pulse ? 1.04 : 1.0)
            // Inner dark ring
            Circle()
                .stroke(Color(hex: "3A2000"), lineWidth: 3)
                .frame(width: size - 8, height: size - 8)
            // Icon
            Image(systemName: isFlow ? "bolt.fill" : "hand.tap.fill")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundColor(.black.opacity(0.55))
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: - Mini Stat Card
struct MiniStatCard: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.amberSubtext)
                .kerning(0.8)
            Text(value)
                .font(AMBERFont.mono(22, weight: .black))
                .foregroundColor(accent ? .amberAccent : .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(Color.amberCard)
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(accent ? Color.amberAccent.opacity(0.4) : Color.amberCardBorder, lineWidth: 1)))
    }
}
