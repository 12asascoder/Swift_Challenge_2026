import SwiftUI

// MARK: - ViewModel
class FlowGridViewModel: ObservableObject {
    @Published var cells: [GridCell] = []
    @Published var phase: GridPhase = .idle
    @Published var message: String = "Tap Start to begin"
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var showConfetti: Bool = false

    enum GridPhase { case idle, showing, input, result }

    struct GridCell: Identifiable {
        let id: Int
        var isHighlighted: Bool = false
        var isUserSelected: Bool = false
        var correct: Bool = false
    }

    var gridSize: Int { min(3 + level - 1, 5) }
    var patternCount: Int { gridSize + level }

    private var pattern: Set<Int> = []

    func startRound() {
        let count = gridSize * gridSize
        cells = (0..<count).map { GridCell(id: $0) }
        pattern = Set((0..<count).shuffled().prefix(patternCount))
        phase = .showing
        message = "Memorize!"
        // Show pattern
        for i in pattern { cells[i].isHighlighted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for i in 0..<self.cells.count { self.cells[i].isHighlighted = false }
            self.phase = .input
            self.message = "Reproduce it!"
        }
    }

    func tapCell(_ id: Int) {
        guard phase == .input else { return }
        cells[id].isUserSelected.toggle()
        checkCompletion()
    }

    private func checkCompletion() {
        let selected = Set(cells.filter { $0.isUserSelected }.map { $0.id })
        guard selected.count == pattern.count else { return }
        let correct = selected == pattern
        if correct {
            score += (level * 100)
            level += 1
            phase = .result
            message = "Perfect! 🎉"
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showConfetti = false
                self.startRound()
            }
        } else {
            message = "Try again 💪"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                for i in 0..<self.cells.count { self.cells[i].isUserSelected = false }
                self.phase = .input
                self.message = "Reproduce it!"
            }
        }
    }
}
