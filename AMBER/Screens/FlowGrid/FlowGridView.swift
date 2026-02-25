import SwiftUI

struct FlowGridView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var vm = FlowGridViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass

    var gridSize: Int { sizeClass == .regular ? 4 : 3 }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 11), count: gridSize)
    }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0B0B08").ignoresSafeArea()

            // Ambient glow on flow complete
            if vm.glowAll {
                RadialGradient(
                    colors: [Color.amberAccent.opacity(0.18), Color.clear],
                    center: .center, startRadius: 0, endRadius: 400
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: vm.glowAll)
            }

            VStack(spacing: 0) {
                headerBar
                subtitleLine
                Spacer(minLength: 20)
                gridArea
                Spacer(minLength: 20)
                flowSyncBar
                exitLink
            }
        }
        .onAppear {
            vm.gridSize = gridSize
            vm.start()
        }
        .onChange(of: vm.gridSize) { _ in }
        .onDisappear { vm.stop() }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button { vm.stop(); appState.activeGame = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.amberCard))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("FLOW GRID")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.amberAccent)
                    .kerning(2.5)
                // Subtle phase indicator
                Text(vm.phase == .watching ? "▶ watching" : vm.phase == .syncing ? "◉ syncing" : vm.phase == .flowing ? "✦ flowing" : "")
                    .font(.system(size: 10))
                    .foregroundColor(.amberSubtext.opacity(0.7))
                    .animation(.easeInOut, value: vm.phase)
            }
            Spacer()
            // Subtle beat indicator
            RhythmDot(phase: vm.phase)
                .frame(width: 34, height: 34)
        }
        .padding(.horizontal, 18)
        .padding(.top, 52)
        .padding(.bottom, 8)
    }

    // MARK: - Subtitle
    private var subtitleLine: some View {
        Text(vm.headerText)
            .font(.system(size: 15, weight: .light).italic())
            .foregroundColor(vm.glowAll ? Color.amberAccent : Color.amberSubtext)
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.4), value: vm.headerText)
            .padding(.horizontal, 40)
            .padding(.bottom, 8)
    }

    // MARK: - Grid
    private var gridArea: some View {
        LazyVGrid(columns: columns, spacing: 11) {
            ForEach(0..<(gridSize * gridSize), id: \.self) { idx in
                RhythmTile(
                    isActive:  vm.activeTiles.contains(idx),
                    isCorrect: vm.correctTiles.contains(idx),
                    isGlow:    vm.glowAll
                ) {
                    vm.tapTile(at: idx)
                }
            }
        }
        .padding(.horizontal, 22)
        .animation(.easeInOut(duration: 0.15), value: vm.activeTiles)
        .animation(.easeInOut(duration: 0.15), value: vm.correctTiles)
        .animation(.easeInOut(duration: 0.6), value: vm.glowAll)
    }

    // MARK: - Flow Sync Bar
    private var flowSyncBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FLOW SYNC")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.amberSubtext)
                    .kerning(2)
                Spacer()
                Text("\(Int(vm.flowSync * 100))%")
                    .font(AMBERFont.mono(12, weight: .bold))
                    .foregroundColor(vm.flowSync >= 1.0 ? .amberAccent : .white)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "222215"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            vm.glowAll
                            ? LinearGradient(colors: [.amberAccent, .cyan, .amberAccent], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.amberAccentDim, .amberAccent], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: g.size.width * vm.flowSync, height: 6)
                        .animation(.easeOut(duration: 0.4), value: vm.flowSync)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    // MARK: - Exit
    private var exitLink: some View {
        Button {
            vm.stop()
            let xp = DataStore.xpFormula(baseScore: Int(vm.flowSync * 800), difficulty: 1.2, streakBonus: 10)
            dataStore.addSession(score: Int(vm.flowSync * 800), xpGained: xp)
            appState.completeSession(score: Int(vm.flowSync * 800), xp: xp)
        } label: {
            Text("End Session")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.amberSubtext.opacity(0.5))
        }
        .padding(.bottom, 28)
    }
}

// MARK: - Rhythm Tile
struct RhythmTile: View {
    let isActive:  Bool
    let isCorrect: Bool
    let isGlow:    Bool
    let onTap: () -> Void

    @State private var bounced     = false
    @State private var rippleScale : CGFloat = 0.6
    @State private var rippleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Ripple ring
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.amberAccent.opacity(rippleOpacity), lineWidth: 1.5)
                .scaleEffect(rippleScale)

            // Tile body
            RoundedRectangle(cornerRadius: 14)
                .fill(tileFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(tileBorder, lineWidth: isActive ? 1.5 : 1)
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(bounced ? 1.07 : 1.0)
        .shadow(color: isActive ? Color.amberAccent.opacity(0.55) : isGlow ? Color.amberAccent.opacity(0.2) : .clear,
                radius: isActive ? 14 : isGlow ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: isActive)
        .animation(.easeInOut(duration: 0.25), value: isCorrect)
        .animation(.easeInOut(duration: 0.5),  value: isGlow)
        .contentShape(Rectangle())
        .onTapGesture {
            // Bounce
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { bounced = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring()) { bounced = false }
            }
            // Ripple
            rippleScale   = 0.5
            rippleOpacity = 0.65
            withAnimation(.easeOut(duration: 0.55)) {
                rippleScale   = 1.4
                rippleOpacity = 0
            }
            onTap()
        }
    }

    private var tileFill: AnyShapeStyle {
        if isGlow {
            return AnyShapeStyle(RadialGradient(colors: [Color.amberAccent.opacity(0.25), Color.amberCard], center: .center, startRadius: 0, endRadius: 40))
        }
        if isActive {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(hex: "3D2A08"), Color(hex: "251A04")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
        if isCorrect {
            return AnyShapeStyle(Color(hex: "192212"))
        }
        return AnyShapeStyle(Color(hex: "161610"))
    }

    private var tileBorder: Color {
        if isGlow    { return Color.amberAccent.opacity(0.7) }
        if isActive  { return Color.amberAccent }
        if isCorrect { return Color.green.opacity(0.35) }
        return Color.amberCardBorder.opacity(0.6)
    }
}

// MARK: - Rhythm Dot (subtle beat indicator in header)
struct RhythmDot: View {
    let phase: RhythmPhase
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.amberCard)
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .opacity(pulse ? 0.5 : 1.0)
        }
        .onAppear {
            guard phase != .idle else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onChange(of: phase) { _ in
            pulse = false
            guard phase != .idle else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private var dotColor: Color {
        switch phase {
        case .idle:     return Color.amberSubtext.opacity(0.3)
        case .watching: return Color.amberSubtext
        case .syncing:  return Color.amberAccent
        case .flowing:  return Color.green
        }
    }
}
