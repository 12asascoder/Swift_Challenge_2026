import SwiftUI

// MARK: - Pattern style
enum PatternStyle: CaseIterable {
    case wave, reverseWave, verticalWave, diagonal, spiral, centerOut
}

// MARK: - Game phase
enum RhythmPhase: Equatable {
    case idle, watching, syncing, flowing
}

// MARK: - ViewModel
class FlowGridViewModel: ObservableObject {
    // Grid state
    @Published var activeTiles : Set<Int> = []
    @Published var correctTiles: Set<Int> = []
    @Published var glowAll: Bool = false
    @Published var phase: RhythmPhase = .idle

    // UI feedback
    @Published var flowSync: Double = 0.0
    @Published var headerText: String = "Sync with the rhythm."
    @Published var glowMessage: String = ""

    // Config
    var gridSize: Int = 3      // set by view on appear
    var beatInterval: TimeInterval = 0.88

    // Private
    private var pattern: [Int] = []
    private var syncIndex: Int = 0
    private var generation: Int = 0  // cancellation token
    private var patternLength: Int = 3
    private var cycleCount: Int = 0
    private var streak: Int = 0
    private var missCount: Int = 0
    private var windowTimer: Timer? = nil

    // MARK: - Entry point
    /// difficulty: 0.0 (easiest) … 1.0 (hardest)
    func start(difficulty: Double = 0.5) {
        generation += 1
        flowSync = 0
        cycleCount = 0
        streak = 0
        missCount = 0
        // Difficulty scaling:
        // pattern length: 2 at easiest → 4 at hardest (capped by grid)
        patternLength = min(max(2, Int(2 + difficulty * 2)), gridSize * gridSize - 1)
        // beat interval: slow (1.10s) for low difficulty, fast (0.65s) for high
        beatInterval = 1.10 - difficulty * 0.45
        buildAndWatch()
    }

    // MARK: - Build pattern → watch phase
    private func buildAndWatch() {
        let gen = generation
        let style = PatternStyle.allCases[cycleCount % PatternStyle.allCases.count]
        pattern = harmonious(size: gridSize, style: style, length: patternLength)

        activeTiles  = []
        correctTiles = []
        phase = .watching
        headerText = "Watch…"

        scheduleWatchSequence(gen: gen)
    }

    private func scheduleWatchSequence(gen: Int) {
        for (i, idx) in pattern.enumerated() {
            let onTime  = Double(i) * beatInterval
            let offTime = onTime + beatInterval * 0.65
            after(onTime,  gen: gen) { self.activeTiles = [idx] }
            after(offTime, gen: gen) { self.activeTiles = [] }
        }
        let done = Double(pattern.count) * beatInterval + 0.3
        after(done, gen: gen) { self.beginSync() }
    }

    // MARK: - Sync phase
    private func beginSync() {
        phase     = .syncing
        syncIndex = 0
        headerText = "Sync ✦"
        correctTiles = []
        pulseNextTile()
    }

    private func pulseNextTile() {
        guard phase == .syncing else { return }
        guard syncIndex < pattern.count else {
            completeCycle(); return
        }
        let idx = pattern[syncIndex]
        activeTiles = [idx]

        // Tap window = beatInterval + 250ms tolerance
        windowTimer?.invalidate()
        windowTimer = Timer.scheduledTimer(withTimeInterval: beatInterval + 0.25, repeats: false) { [weak self] _ in
            self?.handleMiss()
        }
    }

    // MARK: - Tap handler (called from view)
    func tapTile(at index: Int) {
        guard phase == .syncing else { return }
        let expected = syncIndex < pattern.count ? pattern[syncIndex] : -1
        windowTimer?.invalidate()

        if index == expected {
            // Correct
            streak   += 1
            missCount = 0
            correctTiles.insert(index)
            activeTiles = []
            flowSync = min(1.0, flowSync + 0.12 + min(0.05, Double(streak) * 0.008))
            adaptTempo(better: true)
            syncIndex += 1
            after(beatInterval * 0.18, gen: generation) { self.pulseNextTile() }
        } else {
            // Wrong tile – no punishment, just gentle restart
            handleMiss()
        }
    }

    private func handleMiss() {
        guard phase == .syncing else { return }
        streak    = 0
        missCount += 1
        activeTiles = []
        flowSync = max(0, flowSync - 0.04)
        adaptTempo(better: false)
        if missCount >= 3 { patternLength = max(2, patternLength - 1); missCount = 0 }

        headerText = "Sync with the rhythm."
        let gen = generation
        after(0.55, gen: gen) { self.correctTiles = [] }
        after(1.2,  gen: gen) { self.buildAndWatch() }
    }

    // MARK: - Cycle complete
    private func completeCycle() {
        windowTimer?.invalidate()
        cycleCount += 1
        flowSync = min(1.0, flowSync + 0.18)
        adaptTempo(better: true)

        if flowSync >= 1.0 {
            triggerFlow()
        } else {
            headerText = "Sync with the rhythm."
            let gen = generation
            after(0.9, gen: gen) { self.buildAndWatch() }
        }
    }

    private func triggerFlow() {
        phase     = .flowing
        glowAll   = true
        glowMessage = "✦ Perfect Flow ✦"
        headerText  = "✦ Perfect Flow ✦"
        patternLength = min(gridSize * gridSize - 1, patternLength + 1)
        flowSync = 0.55

        let gen = generation
        after(2.2, gen: gen) {
            self.glowAll    = false
            self.glowMessage = ""
            self.buildAndWatch()
        }
    }

    // MARK: - Adaptive tempo
    private func adaptTempo(better: Bool) {
        if better { beatInterval = max(0.50, beatInterval - 0.02) }
        else       { beatInterval = min(1.20, beatInterval + 0.07) }
    }

    // MARK: - Harmonious pattern generator
    private func harmonious(size: Int, style: PatternStyle, length: Int) -> [Int] {
        let n = size * size
        var base: [Int]
        switch style {
        case .wave:
            base = Array(0..<n)
        case .reverseWave:
            base = (0..<n).reversed().map { $0 }
        case .verticalWave:
            base = (0..<size).flatMap { col in (0..<size).map { row in row * size + col } }
        case .diagonal:
            var r: [Int] = []
            for d in 0..<(2 * size - 1) {
                for row in 0..<size {
                    let col = d - row
                    if col >= 0 && col < size { r.append(row * size + col) }
                }
            }
            base = r
        case .spiral:
            base = spiralOrder(size: size)
        case .centerOut:
            let center = (size * size) / 2
            var r: [Int] = [center]
            var ring = 1
            while r.count < n {
                for d in [-ring, ring] {
                    for offset in (-ring...ring) {
                        let idx1 = center + d * size + offset
                        let idx2 = center + offset * size + d
                        [idx1, idx2].forEach { i in
                            if i >= 0 && i < n && !r.contains(i) { r.append(i) }
                        }
                    }
                }
                ring += 1
            }
            base = r
        }
        return Array(base.prefix(length))
    }

    private func spiralOrder(size: Int) -> [Int] {
        var result: [Int] = []
        var top = 0, bottom = size - 1, left = 0, right = size - 1
        while top <= bottom && left <= right {
            for c in left...right { result.append(top * size + c) }
            top += 1
            for r in top...bottom { result.append(r * size + right) }
            right -= 1
            if top <= bottom {
                for c in stride(from: right, through: left, by: -1) { result.append(bottom * size + c) }
                bottom -= 1
            }
            if left <= right {
                for r in stride(from: bottom, through: top, by: -1) { result.append(r * size + left) }
                left += 1
            }
        }
        return result
    }

    // MARK: - Cancellable async helper
    private func after(_ delay: TimeInterval, gen: Int, work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.generation == gen else { return }
            work()
        }
    }

    func stop() { generation += 1; windowTimer?.invalidate() }
    deinit { windowTimer?.invalidate() }
}
