import SwiftUI

struct FlowGridView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var vm = FlowGridViewModel()

    let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var dynamicCols: [GridItem] { Array(repeating: GridItem(.flexible()), count: vm.gridSize) }

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()

            // Confetti layer
            if vm.showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }

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
                        Text("FLOW GRID")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.amberAccent).kerning(2)
                        Text("\(vm.score)")
                            .font(AMBERFont.mono(28, weight: .black))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("LVL \(vm.level)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.amberAccent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Text(vm.message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.amberSubtext)
                    .padding(.top, 10)
                    .animation(.easeInOut, value: vm.message)

                Spacer()

                // Grid
                LazyVGrid(columns: dynamicCols, spacing: 10) {
                    ForEach(vm.cells) { cell in
                        Button {
                            withAnimation(.spring(response: 0.2)) { vm.tapCell(cell.id) }
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cellColor(cell))
                                .frame(height: cellHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(cellBorder(cell), lineWidth: 1.5)
                                )
                        }
                        .scaleEffect(cell.isHighlighted || cell.isUserSelected ? 1.05 : 1.0)
                        .disabled(vm.phase != .input)
                    }
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.3), value: vm.gridSize)

                Spacer()

                // Start button
                if vm.phase == .idle || vm.phase == .result {
                    Button {
                        vm.startRound()
                    } label: {
                        Text(vm.phase == .idle ? "Start Flow" : "Next Level")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.amberAccent))
                    }
                    .padding(.bottom, 16)
                }

                // Done button
                Button {
                    let xp = DataStore.xpFormula(baseScore: vm.score, difficulty: 1.2, streakBonus: 15)
                    dataStore.addSession(score: vm.score, xpGained: xp)
                    appState.completeSession(score: vm.score, xp: xp)
                } label: {
                    Text("End Session")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.amberSubtext)
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var cellHeight: CGFloat {
        let screen = UIScreen.main.bounds.width - 48
        return screen / CGFloat(vm.gridSize)
    }

    private func cellColor(_ cell: FlowGridViewModel.GridCell) -> Color {
        if cell.isHighlighted { return .amberAccent }
        if cell.isUserSelected { return Color.amberAccent.opacity(0.5) }
        return .amberCard
    }

    private func cellBorder(_ cell: FlowGridViewModel.GridCell) -> Color {
        if cell.isHighlighted { return .amberAccent }
        if cell.isUserSelected { return Color.amberAccent.opacity(0.8) }
        return .amberCardBorder
    }
}

// MARK: - Confetti
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<40).map { _ in ConfettiParticle() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                for i in particles.indices {
                    particles[i].y += CGFloat.random(in: 200...600)
                    particles[i].x += CGFloat.random(in: -100...100)
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: -160...160)
    var y: CGFloat = CGFloat.random(in: -300...0)
    var size: CGFloat = CGFloat.random(in: 6...14)
    var opacity: Double = 1.0
    var color: Color = [Color.amberAccent, .green, .cyan, .pink, .white].randomElement()!
}
