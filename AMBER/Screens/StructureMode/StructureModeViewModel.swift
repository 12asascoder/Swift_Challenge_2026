import SwiftUI

// MARK: - Piece
struct BlockPiece: Identifiable {
    let id = UUID()
    var cells: [[Bool]]
    var color: Color

    mutating func rotate() {
        guard !cells.isEmpty else { return }
        let rows = cells.count, cols = cells[0].count
        var rot = Array(repeating: Array(repeating: false, count: rows), count: cols)
        for r in 0..<rows { for c in 0..<cols { rot[c][rows - 1 - r] = cells[r][c] } }
        cells = rot
    }
    var width:  Int { cells.isEmpty ? 0 : cells[0].count }
    var height: Int { cells.count }
}

// MARK: - ViewModel
class StructureModeViewModel: ObservableObject {
    static let COLS = 10
    static let ROWS = 10

    @Published var grid: [[Color?]] = Array(repeating: Array(repeating: nil, count: COLS), count: ROWS)
    @Published var tray: [BlockPiece] = []
    @Published var stability: Double = 0
    @Published var sessionEnded: Bool = false

    static let shapes: [[[Bool]]] = [
        [[true, true, true]],
        [[true, true], [true, true]],
        [[true, false], [true, false], [true, true]],
        [[false, true], [false, true], [true, true]],
        [[false, true, false], [true, true, true]],
        [[false, true, true], [true, true, false]],
        [[true, true, false], [false, true, true]],
        [[true]], [[true, true]],
    ]
    static let pieceColors: [Color] = [
        Color.amberAccent, Color(hex: "C49020"), Color(hex: "8B6B14"), Color(hex: "A07828")
    ]

    // MARK: - Lifecycle
    func start() {
        grid = Array(repeating: Array(repeating: nil, count: Self.COLS), count: Self.ROWS)
        stability = 0; sessionEnded = false; tray = []
        refillTray()
    }

    private func refillTray() { while tray.count < 3 { tray.append(randomPiece()) } }
    private func randomPiece() -> BlockPiece {
        BlockPiece(cells: Self.shapes.randomElement()!, color: Self.pieceColors.randomElement()!)
    }

    // MARK: - Drag-drop placement (called from view)
    func rotatePiece(at idx: Int) {
        guard idx < tray.count else { return }
        tray[idx].rotate()
    }

    /// Returns true if placement was valid
    @discardableResult
    func tryPlace(pieceIdx: Int, gridRow: Int, gridCol: Int) -> Bool {
        guard pieceIdx < tray.count else { return false }
        let piece = tray[pieceIdx]
        guard canPlace(piece, row: gridRow, col: gridCol) else { return false }
        place(piece, row: gridRow, col: gridCol)
        tray.remove(at: pieceIdx)
        checkLines()
        refillTray()
        if !hasAnyMove() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.sessionEnded = true }
        }
        return true
    }

    // MARK: - Helpers
    func canPlace(_ piece: BlockPiece, row: Int, col: Int) -> Bool {
        for r in 0..<piece.height {
            for c in 0..<piece.width where piece.cells[r][c] {
                let gr = row + r, gc = col + c
                if gr >= Self.ROWS || gc >= Self.COLS || gc < 0 || gr < 0 { return false }
                if grid[gr][gc] != nil { return false }
            }
        }
        return true
    }

    private func place(_ piece: BlockPiece, row: Int, col: Int) {
        for r in 0..<piece.height {
            for c in 0..<piece.width where piece.cells[r][c] {
                grid[row + r][col + c] = piece.color
            }
        }
    }

    private func checkLines() {
        let fullRows = (0..<Self.ROWS).filter { grid[$0].allSatisfy { $0 != nil } }
        let fullCols = (0..<Self.COLS).filter { c in (0..<Self.ROWS).allSatisfy { grid[$0][c] != nil } }
        guard !fullRows.isEmpty || !fullCols.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            for r in fullRows { for c in 0..<Self.COLS { grid[r][c] = nil } }
            for c in fullCols { for r in 0..<Self.ROWS { grid[r][c] = nil } }
        }
        let n = fullRows.count + fullCols.count
        stability = min(1.0, stability + Double(n) * 0.09)
    }

    private func hasAnyMove() -> Bool {
        for piece in tray {
            for r in 0...(Self.ROWS - piece.height) {
                for c in 0...(Self.COLS - piece.width) {
                    if canPlace(piece, row: r, col: c) { return true }
                }
            }
        }
        return false
    }
}
