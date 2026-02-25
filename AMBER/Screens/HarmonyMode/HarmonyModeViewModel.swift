import SwiftUI

// MARK: - Liquid colour enum
enum LiquidColor: Int, CaseIterable, Equatable, Hashable {
    case violet, cyan, amber, coral, sage, rose
    var swiftColor: Color {
        switch self {
        case .violet: return Color(hex: "9C5AF0")
        case .cyan:   return Color(hex: "0ECECE")
        case .amber:  return Color.amberAccent
        case .coral:  return Color(hex: "FF6B6B")
        case .sage:   return Color(hex: "6BCF7F")
        case .rose:   return Color(hex: "F06292")
        }
    }
}

// MARK: - ViewModel
class HarmonyModeViewModel: ObservableObject {
    static let capacity = 4

    @Published var tubes: [[LiquidColor]] = []
    @Published var selected: Int? = nil
    @Published var harmony: Double = 0
    @Published var shaking: Int? = nil
    @Published var solved: Bool = false
    @Published var colorCount: Int = 3
    @Published var solveCount: Int = 0

    // MARK: - Setup
    func startFresh() {
        solveCount = 0
        colorCount = 3
        buildPuzzle(colors: 3)
    }

    func nextPuzzle() {
        solveCount += 1
        // +15% difficulty per solve: add a new color every ~2 completions
        colorCount = min(LiquidColor.allCases.count, 3 + solveCount / 2)
        solved = false
        buildPuzzle(colors: colorCount)
    }

    // Keep for Reset button (resets to current difficulty, not fresh start)
    func newPuzzle(colors: Int) {
        buildPuzzle(colors: colors)
    }

    private func buildPuzzle(colors: Int) {
        var balls: [LiquidColor] = []
        LiquidColor.allCases.prefix(colors).forEach { c in balls += Array(repeating: c, count: Self.capacity) }
        var attempts = 0
        repeat {
            balls.shuffle()
            attempts += 1
        } while isTrivial(balls, n: colors) && attempts < 20

        tubes = stride(from: 0, to: colors * Self.capacity, by: Self.capacity).map {
            Array(balls[$0..<$0 + Self.capacity])
        }
        // Extra empty tubes: 2 for 3 colors, 3 for 4+
        let emptyCount = colors <= 3 ? 2 : 3
        tubes += Array(repeating: [], count: emptyCount)
        selected = nil
        harmony = 0
    }

    private func isTrivial(_ balls: [LiquidColor], n: Int) -> Bool {
        for i in 0..<n {
            let slice = balls[i * Self.capacity..<(i + 1) * Self.capacity]
            if Set(slice).count == 1 { return true }
        }
        return false
    }

    // MARK: - Tap
    func tap(_ idx: Int) {
        guard idx < tubes.count else { return }
        if let from = selected {
            if from == idx { selected = nil; return }
            if canMove(from: from, to: idx) {
                move(from: from, to: idx)
            } else {
                triggerShake(idx)
            }
            selected = nil
        } else {
            if !tubes[idx].isEmpty { selected = idx }
        }
    }

    func canMove(from: Int, to: Int) -> Bool {
        guard from != to, from < tubes.count, to < tubes.count,
              let topFrom = tubes[from].last else { return false }
        if tubes[to].count >= Self.capacity { return false }
        if tubes[to].isEmpty { return true }
        return tubes[to].last == topFrom
    }

    private func move(from: Int, to: Int) {
        guard let ball = tubes[from].last else { return }
        tubes[from].removeLast()
        tubes[to].append(ball)
        updateHarmony()
        checkSolved()
    }

    // MARK: - State
    private func updateHarmony() {
        let complete = tubes.filter { isUniform($0) }.count
        harmony = tubes.isEmpty ? 0 : Double(complete) / Double(colorCount)
    }

    func isUniform(_ tube: [LiquidColor]) -> Bool {
        guard tube.count == Self.capacity else { return false }
        return Set(tube).count == 1
    }

    private func checkSolved() {
        let done = tubes.filter { !$0.isEmpty }.allSatisfy { isUniform($0) }
        if done { DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.solved = true } }
    }

    private func triggerShake(_ idx: Int) {
        shaking = idx
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.shaking = nil }
    }
}
