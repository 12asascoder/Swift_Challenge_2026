import SwiftUI
import Combine

// ╔══════════════════════════════════════════════════════════════╗
// ║  ZEN BLOCKS  —  Calm Spatial Construction Ritual            ║
// ║  Architecture: GridEngine · BlockGenerator · SessionManager ║
// ╚══════════════════════════════════════════════════════════════╝

// MARK: - GridCell
struct GridCell: Equatable {
    var isOccupied: Bool = false
    var color: Color? = nil
    /// True while a line-clear dissolve animation is running
    var isClearing: Bool = false
}

// MARK: - Block
struct Block: Identifiable, Equatable {
    let id = UUID()
    var shape: [[Int]]            // 1 = filled, 0 = empty
    var color: Color

    var width:  Int { shape.first?.count ?? 0 }
    var height: Int { shape.count }

    /// Rotate 90° clockwise
    mutating func rotate() {
        guard !shape.isEmpty else { return }
        let rows = shape.count, cols = shape[0].count
        var rot = Array(repeating: Array(repeating: 0, count: rows), count: cols)
        for r in 0..<rows { for c in 0..<cols { rot[c][rows - 1 - r] = shape[r][c] } }
        shape = rot
    }

    static func == (lhs: Block, rhs: Block) -> Bool { lhs.id == rhs.id }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - GridEngine
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct GridEngine {
    static let rows = 10
    static let cols = 10

    // MARK: Validate
    static func canPlace(_ block: Block, at row: Int, col: Int, in grid: [[GridCell]]) -> Bool {
        for r in 0..<block.height {
            for c in 0..<block.width where block.shape[r][c] == 1 {
                let gr = row + r, gc = col + c
                guard gr >= 0, gr < rows, gc >= 0, gc < cols else { return false }
                if grid[gr][gc].isOccupied { return false }
            }
        }
        return true
    }

    // MARK: Place
    static func place(_ block: Block, at row: Int, col: Int, in grid: inout [[GridCell]]) {
        for r in 0..<block.height {
            for c in 0..<block.width where block.shape[r][c] == 1 {
                grid[row + r][col + c] = GridCell(isOccupied: true, color: block.color)
            }
        }
    }

    // MARK: Detect completed lines
    struct ClearedLines {
        let rows: [Int]
        let cols: [Int]
        var count: Int { rows.count + cols.count }
        var isEmpty: Bool { rows.isEmpty && cols.isEmpty }
    }

    static func detectCompletedLines(in grid: [[GridCell]]) -> ClearedLines {
        let fullRows = (0..<rows).filter { r in grid[r].allSatisfy { $0.isOccupied } }
        let fullCols = (0..<cols).filter { c in (0..<rows).allSatisfy { grid[$0][c].isOccupied } }
        return ClearedLines(rows: fullRows, cols: fullCols)
    }

    // MARK: Mark lines for clearing animation
    static func markClearing(_ lines: ClearedLines, in grid: inout [[GridCell]]) {
        for r in lines.rows { for c in 0..<cols { grid[r][c].isClearing = true } }
        for c in lines.cols { for r in 0..<rows { grid[r][c].isClearing = true } }
    }

    // MARK: Clear lines
    static func clearLines(_ lines: ClearedLines, in grid: inout [[GridCell]]) {
        for r in lines.rows { for c in 0..<cols { grid[r][c] = GridCell() } }
        for c in lines.cols { for r in 0..<rows { grid[r][c] = GridCell() } }
    }

    // MARK: Grid density
    static func density(of grid: [[GridCell]]) -> Double {
        let total = Double(rows * cols)
        let filled = Double(grid.flatMap { $0 }.filter { $0.isOccupied }.count)
        return filled / total
    }

    // MARK: Any move possible?
    static func hasAnyMove(for blocks: [Block], in grid: [[GridCell]]) -> Bool {
        for block in blocks {
            var rotated = block
            for _ in 0..<4 {
                let maxR = max(0, rows - rotated.height)
                let maxC = max(0, cols - rotated.width)
                for r in 0...maxR {
                    for c in 0...maxC {
                        if canPlace(rotated, at: r, col: c, in: grid) { return true }
                    }
                }
                rotated.rotate()
            }
        }
        return false
    }

    // MARK: Snap-to-grid
    static func snapToGrid(
        location: CGPoint,
        gridFrame: CGRect,
        block: Block
    ) -> (row: Int, col: Int)? {
        let pad: CGFloat = 6
        let localX = location.x - gridFrame.minX - pad
        let localY = location.y - gridFrame.minY - pad
        let innerW = gridFrame.width - pad * 2
        let spacing: CGFloat = 2
        let cs = max(1, (innerW - CGFloat(cols - 1) * spacing) / CGFloat(cols))
        guard cs > 0 else { return nil }

        let rawCol = Int(localX / (cs + spacing))
        let rawRow = Int(localY / (cs + spacing))
        let col = max(0, min(cols - block.width,  rawCol))
        let row = max(0, min(rows - block.height, rawRow))
        return (row, col)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - BlockGenerator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct BlockGenerator {

    enum ShapeCategory: CaseIterable {
        case tiny, small, medium, lShape, tShape, zigzag
    }

    static let shapePool: [(shape: [[Int]], category: ShapeCategory)] = [
        // ── Tiny ──
        ([[1]],                                  .tiny),
        ([[1, 1]],                               .tiny),
        ([[1], [1]],                             .tiny),
        // ── Small ──
        ([[1, 1], [1, 1]],                       .small),
        ([[1, 1, 1]],                            .small),
        ([[1], [1], [1]],                        .small),
        // ── Medium ──
        ([[1, 1, 1, 1]],                         .medium),
        ([[1], [1], [1], [1]],                   .medium),
        // ── L shapes ──
        ([[1, 0], [1, 0], [1, 1]],              .lShape),
        ([[0, 1], [0, 1], [1, 1]],              .lShape),
        ([[1, 1], [1, 0]],                       .lShape),
        ([[1, 1], [0, 1]],                       .lShape),
        // ── Small T shapes ──
        ([[1, 1, 1], [0, 1, 0]],                .tShape),
        ([[0, 1], [1, 1], [0, 1]],              .tShape),
        // ── Zigzag ──
        ([[1, 1, 0], [0, 1, 1]],                .zigzag),
        ([[0, 1, 1], [1, 1, 0]],                .zigzag),
    ]

    static let blockColors: [Color] = [
        Color(hex: "F5A623"),
        Color(hex: "D4912A"),
        Color(hex: "B87D1E"),
        Color(hex: "C49535"),
        Color(hex: "A08030"),
    ]

    static func generate(
        gridDensity: Double,
        invalidAttempts: Int,
        placementStreak: Int
    ) -> Block {
        var weights: [Double] = shapePool.map { entry in
            switch entry.category {
            case .tiny:   return 1.0
            case .small:  return 0.9
            case .medium: return 0.4
            case .lShape: return 0.5
            case .tShape: return 0.4
            case .zigzag: return 0.3
            }
        }

        // High density → favour small blocks
        if gridDensity > 0.7 {
            for i in weights.indices {
                switch shapePool[i].category {
                case .tiny:            weights[i] *= 2.5
                case .small:           weights[i] *= 1.8
                case .medium, .zigzag: weights[i] *= 0.2
                case .lShape, .tShape: weights[i] *= 0.4
                }
            }
        } else if gridDensity > 0.5 {
            for i in weights.indices {
                if shapePool[i].category == .tiny  { weights[i] *= 1.5 }
                if shapePool[i].category == .small { weights[i] *= 1.3 }
            }
        }

        // Many invalid attempts → simplify
        if invalidAttempts > 3 {
            for i in weights.indices {
                switch shapePool[i].category {
                case .tiny, .small: weights[i] *= 2.0
                default:            weights[i] *= 0.3
                }
            }
        }

        // Good streak → allow moderate complexity
        if placementStreak > 6 {
            for i in weights.indices {
                if shapePool[i].category == .lShape || shapePool[i].category == .tShape {
                    weights[i] *= 1.5
                }
                if shapePool[i].category == .medium { weights[i] *= 1.2 }
            }
        }

        // Weighted pick
        let total = weights.reduce(0, +)
        var pick = Double.random(in: 0..<total)
        var idx = 0
        for (i, w) in weights.enumerated() {
            pick -= w
            if pick <= 0 { idx = i; break }
        }

        return Block(shape: shapePool[idx].shape, color: blockColors.randomElement()!)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SessionManager
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct SessionManager {
    static let zenPerLine: Float  = 0.15
    static let streakBonus: Float = 0.02
    static let maxZen: Float      = 1.0

    static func updateZenProgress(
        current: Float,
        linesCleared: Int,
        cleanStreak: Int
    ) -> Float {
        var zen = current
        zen += Float(linesCleared) * zenPerLine
        if linesCleared > 0 && cleanStreak > 2 {
            zen += Float(min(cleanStreak, 10)) * streakBonus
        }
        return min(zen, maxZen)
    }

    static func isSessionOver(zenProgress: Float, hasMovesLeft: Bool) -> Bool {
        zenProgress >= maxZen || !hasMovesLeft
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - StructureModeViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final class StructureModeViewModel: ObservableObject {
    static let ROWS = GridEngine.rows
    static let COLS = GridEngine.cols

    // ── Published state ──
    @Published var grid: [[GridCell]] = []
    @Published var tray: [Block] = []
    @Published var zenProgress: Float = 0
    @Published var sessionEnded: Bool = false
    @Published var showZenGlow: Bool = false

    // ── Session stats ──
    @Published var linesCleared: Int = 0
    @Published var totalPlacements: Int = 0
    @Published var invalidAttempts: Int = 0
    @Published var placementStreak: Int = 0
    @Published var cleanPlacementCount: Int = 0

    var sessionStartTime = Date()
    private var isAnimatingClear = false

    var cleanPlacementPercent: Double {
        guard totalPlacements > 0 else { return 1.0 }
        return Double(cleanPlacementCount) / Double(totalPlacements)
    }

    var sessionDurationFormatted: String {
        let secs = Int(Date().timeIntervalSince(sessionStartTime))
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    // MARK: - Start
    func start(difficulty: Double = 0.5) {
        grid = Array(repeating: Array(repeating: GridCell(), count: Self.COLS), count: Self.ROWS)
        zenProgress = 0
        sessionEnded = false
        showZenGlow = false
        linesCleared = 0
        totalPlacements = 0
        invalidAttempts = 0
        placementStreak = 0
        cleanPlacementCount = 0
        sessionStartTime = Date()
        isAnimatingClear = false
        tray = []
        refillTray()
    }

    // MARK: - Tray
    private func refillTray() {
        guard tray.isEmpty else { return }
        let d = GridEngine.density(of: grid)
        for _ in 0..<3 {
            tray.append(BlockGenerator.generate(
                gridDensity: d,
                invalidAttempts: invalidAttempts,
                placementStreak: placementStreak
            ))
        }
    }

    // MARK: - Rotate
    func rotatePiece(at idx: Int) {
        guard idx < tray.count else { return }
        tray[idx].rotate()
    }

    // MARK: - Try placement
    @discardableResult
    func tryPlace(pieceIdx: Int, gridRow: Int, gridCol: Int) -> Bool {
        guard pieceIdx < tray.count, !isAnimatingClear else { return false }
        let block = tray[pieceIdx]

        guard GridEngine.canPlace(block, at: gridRow, col: gridCol, in: grid) else {
            invalidAttempts += 1
            placementStreak = 0
            triggerHaptic(.light)
            return false
        }

        // Valid
        GridEngine.place(block, at: gridRow, col: gridCol, in: &grid)
        tray.remove(at: pieceIdx)
        totalPlacements += 1
        cleanPlacementCount += 1
        placementStreak += 1
        triggerHaptic(.medium)

        let cleared = GridEngine.detectCompletedLines(in: grid)
        if !cleared.isEmpty {
            animateLineClear(cleared)
        } else {
            afterPlacement()
        }
        return true
    }

    // MARK: - Line clear
    private func animateLineClear(_ lines: GridEngine.ClearedLines) {
        isAnimatingClear = true

        // Phase 1: soft highlight
        withAnimation(.easeInOut(duration: 0.25)) {
            GridEngine.markClearing(lines, in: &grid)
        }

        // Phase 2: dissolve after brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                GridEngine.clearLines(lines, in: &self.grid)
            }

            self.linesCleared += lines.count
            self.triggerHaptic(.soft)

            self.zenProgress = SessionManager.updateZenProgress(
                current: self.zenProgress,
                linesCleared: lines.count,
                cleanStreak: self.placementStreak
            )

            // Zen glow at 100%
            if self.zenProgress >= 1.0 {
                withAnimation(.easeInOut(duration: 0.6)) { self.showZenGlow = true }
            }

            self.isAnimatingClear = false
            self.afterPlacement()
        }
    }

    // MARK: - After placement
    private func afterPlacement() {
        if tray.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) { refillTray() }
        }

        let hasMove = GridEngine.hasAnyMove(for: tray, in: grid)
        if SessionManager.isSessionOver(zenProgress: zenProgress, hasMovesLeft: hasMove) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                withAnimation(.easeInOut(duration: 0.4)) {
                    self?.sessionEnded = true
                }
            }
        }
    }

    // MARK: - Haptics
    enum HapticWeight { case light, medium, soft }
    func triggerHaptic(_ weight: HapticWeight) {
        #if os(iOS)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        let intensity: CGFloat
        switch weight {
        case .light:  style = .light;  intensity = 0.35
        case .medium: style = .medium; intensity = 0.5
        case .soft:   style = .soft;   intensity = 0.55
        }
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred(intensity: intensity)
        #endif
    }
}
