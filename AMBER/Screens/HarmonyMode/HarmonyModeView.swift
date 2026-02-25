import SwiftUI

struct HarmonyModeView: View {
    @StateObject private var vm = HarmonyModeViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore

    // Animation tracking
    @State private var solvedPulse = false

    var body: some View {
        ZStack {
            Color(hex: "0C0C0A").ignoresSafeArea()

            // Ambient glow that pulses on solve
            RadialGradient(
                colors: [Color.amberAccent.opacity(vm.solved ? 0.18 : 0.04), .clear],
                center: .center, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2), value: vm.solved)

            VStack(spacing: 0) {
                headerBar
                Spacer(minLength: 10)
                tubeGrid
                Spacer(minLength: 10)
                hintText
                harmonyBar.padding(.horizontal, 20).padding(.vertical, 16)
                difficultyRow.padding(.horizontal, 24).padding(.bottom, 30)
            }
        }
        .onAppear { vm.startFresh() }
        .sheet(isPresented: $vm.solved) { solvedOverlay }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button { appState.activeGame = nil } label: {
                Image(systemName: "chevron.left").foregroundColor(.white)
                    .frame(width: 34, height: 34).background(Circle().fill(Color.amberCard))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("ZEN SORT")
                    .font(.system(size: 13, weight: .bold)).kerning(2.5).foregroundColor(.amberAccent)
                Text("ROUND \(vm.solveCount + 1)")
                    .font(.system(size: 9, weight: .semibold)).kerning(1.5).foregroundColor(.amberSubtext)
                    .animation(.easeInOut, value: vm.solveCount)
            }
            Spacer()
            Button { vm.newPuzzle(colors: vm.colorCount) } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                    Text("Reset")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.amberAccent)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Color.amberCard)
                    .overlay(Capsule().stroke(Color.amberAccent.opacity(0.5), lineWidth: 1)))
            }
        }
        .padding(.horizontal, 16).padding(.top, 52).padding(.bottom, 16)
    }

    // MARK: - Tube grid
    private var tubeGrid: some View {
        VStack(spacing: 20) {
            // First row: all filled tubes (up to 4)
            let filledCount  = min(4, vm.colorCount)
            let emptyCount   = vm.tubes.count - vm.colorCount
            let emptyStart   = vm.colorCount

            HStack(spacing: 16) {
                ForEach(0..<min(filledCount, vm.tubes.count), id: \.self) { i in
                    tubeCell(i)
                }
            }
            // Overflow filled tubes into second row
            if vm.colorCount > 4 {
                HStack(spacing: 16) {
                    ForEach(4..<min(vm.colorCount, vm.tubes.count), id: \.self) { i in
                        tubeCell(i)
                    }
                }
            }
            // Empty tubes row
            if emptyStart < vm.tubes.count {
                HStack(spacing: 16) {
                    Spacer()
                    ForEach(emptyStart..<min(emptyStart + 3, vm.tubes.count), id: \.self) { i in
                        tubeCell(i)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func tubeCell(_ i: Int) -> some View {
        let isSelected = vm.selected == i
        let complete   = i < vm.tubes.count ? vm.isUniform(vm.tubes[i]) : false
        return TubeView(
            colors: i < vm.tubes.count ? vm.tubes[i] : [],
            capacity: HarmonyModeViewModel.capacity,
            isSelected: isSelected,
            isComplete: complete
        )
        .frame(width: 82, height: 210)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .modifier(ShakeEffect(trigger: vm.shaking == i))
        .shadow(
            color: complete   ? Color.green.opacity(0.35) :
                   isSelected ? Color.amberAccent.opacity(0.4) : .clear,
            radius: 14
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { vm.tap(i) }
        }
    }

    // MARK: - Hint
    private var hintText: some View {
        Text("Sort the glowing isotopes by molecular density")
            .font(.system(size: 13).italic()).foregroundColor(.amberSubtext)
            .multilineTextAlignment(.center).padding(.horizontal, 40)
    }

    // MARK: - Harmony bar
    private var harmonyBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("HARMONY")
                    .font(.system(size: 10, weight: .bold)).kerning(2).foregroundColor(.amberSubtext)
                Spacer()
                Text("\(Int(vm.harmony * 100))%")
                    .font(AMBERFont.mono(12, weight: .bold)).foregroundColor(.amberAccent)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "222215")).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [Color.amberAccentDim, Color.amberAccent],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, g.size.width * vm.harmony), height: 6)
                        .animation(.easeOut(duration: 0.5), value: vm.harmony)
                }
            }.frame(height: 6)
        }
    }

    // MARK: - Difficulty row (replacing Skip Level)
    private var difficultyRow: some View {
        HStack(spacing: 10) {
            // Difficulty pips (1 per color used)
            HStack(spacing: 5) {
                ForEach(0..<vm.colorCount, id: \.self) { i in
                    Circle()
                        .fill(LiquidColor.allCases[i].swiftColor)
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: vm.colorCount)
                }
            }
            Spacer()
            Text("Difficulty +\(vm.solveCount > 0 ? Int(Double(vm.solveCount) * 15) : 0)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.amberSubtext.opacity(0.7))
                .animation(.easeInOut, value: vm.solveCount)
        }
    }

    // MARK: - Solved overlay
    private var solvedOverlay: some View {
        ZStack {
            Color(hex: "0C0C0A").ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer(minLength: 30)
                Text("✦ Sorted")
                    .font(.system(size: 32, weight: .black)).foregroundColor(.amberAccent)
                Text("Round \(vm.solveCount + 1) complete")
                    .font(.system(size: 16)).foregroundColor(.amberSubtext)
                // Next difficulty preview
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.amberAccent)
                    let nextColors = min(LiquidColor.allCases.count, 3 + (vm.solveCount + 1) / 2)
                    Text(nextColors > vm.colorCount
                         ? "Next round: \(nextColors) colors (+difficulty!)"
                         : "Next round: same difficulty")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.amberCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.amberAccent.opacity(0.3))))
                .padding(.horizontal, 30)

                Button { vm.nextPuzzle() } label: {
                    Text("Continue →")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.amberAccent))
                        .padding(.horizontal, 30)
                }
                Button { vm.solved = false; appState.activeGame = nil } label: {
                    Text("Exit Session")
                        .font(.system(size: 15)).foregroundColor(.amberSubtext)
                }
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.55)])
    }
}

// MARK: - Tube View
struct TubeView: View {
    let colors: [LiquidColor]
    let capacity: Int
    let isSelected: Bool
    let isComplete: Bool

    var body: some View {
        GeometryReader { geo in
            let segH = capacity > 0 ? geo.size.height / CGFloat(capacity) : 0
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "1E1E14").opacity(0.85))

                VStack(spacing: 0) {
                    let empty = max(0, capacity - colors.count)
                    ForEach(0..<empty, id: \.self) { _ in
                        Rectangle().fill(Color.clear).frame(height: segH)
                    }
                    ForEach(Array(colors.reversed().enumerated()), id: \.offset) { _, lc in
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [lc.swiftColor, lc.swiftColor.opacity(0.75)],
                                startPoint: .top, endPoint: .bottom))
                            .frame(height: segH)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal:   .move(edge: .bottom).combined(with: .opacity)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.68), value: colors.count)
                .clipShape(RoundedRectangle(cornerRadius: 22))

                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isSelected ? Color.amberAccent :
                        isComplete ? Color.green.opacity(0.9) :
                        Color.white.opacity(0.12),
                        lineWidth: isSelected ? 2.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                if isComplete {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.green.opacity(0.08))
                        .transition(.opacity)
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.amberAccent.opacity(0.06))
                }
            }
        }
    }
}

// MARK: - Shake modifier
struct ShakeEffect: GeometryEffect {
    var trigger: Bool
    @State private var phase: CGFloat = 0
    var animatableData: CGFloat { get { phase } set { phase = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard trigger else { return .init(.identity) }
        let x = 8 * sin(phase * .pi * 4)
        return .init(CGAffineTransform(translationX: x, y: 0))
    }
}
