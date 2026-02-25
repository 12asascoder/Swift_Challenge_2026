import SwiftUI
import QuartzCore

// MARK: - Enums
enum MovementPhase: CaseIterable {
    case drift, burst, spiral, evasive
}

enum HitQuality: String {
    case perfect = "PERFECT!"
    case good    = "GOOD"
    case weak    = "WEAK"
    case miss    = "MISS"
    var xp: Int { switch self { case .perfect: return 100; case .good: return 60; case .weak: return 30; case .miss: return 0 } }
    var color: Color { switch self { case .perfect: return .amberAccent; case .good: return .green; case .weak: return .yellow; case .miss: return .red } }
}

// MARK: - ViewModel
class FocusArenaViewModel: ObservableObject {
    // Position / motion
    @Published var corePosition: CGPoint = CGPoint(x: 200, y: 300)
    @Published var coreSize: CGFloat = 110
    // State
    @Published var score: Int       = 0
    @Published var multiplier: Double = 1.0
    @Published var combo: Int       = 0
    @Published var bestCombo: Int   = 0
    @Published var syncPercent: Double = 0
    @Published var timeLeft: Int    = 30
    @Published var isRunning: Bool  = false
    @Published var sessionEnded: Bool = false
    @Published var lastHit: HitQuality? = nil
    @Published var isFlowMode: Bool = false
    @Published var isShrinkMode: Bool = false
    @Published var lastReactionMs: Double = 0
    @Published var currentPhase: MovementPhase = .drift
    @Published var showHitFeedback: Bool = false

    // Private physics
    var bounds: CGSize = .zero
    private var velocity = CGVector(dx: 2.5, dy: 1.8)
    private var phaseElapsed: Double = 0
    private var phaseDuration: Double = 5
    private var spiralAngle: Double = 0
    private var sessionElapsed: Double = 0
    private var displayLink: CADisplayLink?
    private var prevTime: CFTimeInterval = 0
    private var tapTimestamp: Date? = nil
    private var totalReactionMs: Double = 0
    private var hitCount: Int = 0

    // MARK: - Public API
    func start() {
        guard !isRunning else { return }
        resetState()
        isRunning = true
        prevTime = CACurrentMediaTime()
        displayLink?.invalidate()
        let dl = CADisplayLink(target: self, selector: #selector(onFrame))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    private func resetState() {
        score = 0; multiplier = 1; combo = 0; bestCombo = 0
        syncPercent = 0; timeLeft = 30; sessionEnded = false
        lastHit = nil; isFlowMode = false; isShrinkMode = false
        phaseElapsed = 0; phaseDuration = 5; sessionElapsed = 0
        spiralAngle = 0; coreSize = 110; totalReactionMs = 0; hitCount = 0
        corePosition = CGPoint(x: bounds.width / 2, y: bounds.height * 0.38)
        velocity = CGVector(dx: 2.5, dy: 1.8)
    }

    @objc private func onFrame() {
        let now = CACurrentMediaTime()
        let dt  = now - prevTime
        prevTime = now
        guard isRunning, bounds.width > 0 else { return }

        sessionElapsed += dt
        let remaining = max(0, 30 - Int(sessionElapsed))
        if remaining != timeLeft {
            DispatchQueue.main.async { self.timeLeft = remaining }
        }
        if sessionElapsed >= 30 {
            endSession(); return
        }
        // Tap availability window
        tapTimestamp = Date()
        updatePhase(dt: dt)
        moveCore(dt: dt)
    }

    private func updatePhase(dt: Double) {
        phaseElapsed += dt
        if phaseElapsed >= phaseDuration { switchPhase() }
    }

    private func switchPhase() {
        phaseElapsed = 0
        phaseDuration = Double.random(in: 4...6)
        var pool: [MovementPhase] = [.drift]
        if sessionElapsed > 5  { pool.append(.burst) }
        if sessionElapsed > 10 { pool.append(.spiral) }
        if sessionElapsed > 15 { pool.append(.evasive) }
        let others = pool.filter { $0 != currentPhase }
        currentPhase = (others.isEmpty ? pool : others).randomElement()!

        let speed = 2.5 + (sessionElapsed / 30.0) * 3.0
        let angle = Double.random(in: 0...(2 * .pi))
        velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

        if !isShrinkMode && Double.random(in: 0...1) < 0.18 { triggerShrink() }
    }

    private func moveCore(dt: Double) {
        let margin = coreSize / 2 + 20
        guard bounds.width > 0 else { return }

        let speedMult: CGFloat = isShrinkMode ? 1.4 : 1.0
        let base = CGFloat(dt) * 60 * speedMult

        var newPos = corePosition
        switch currentPhase {
        case .drift:
            newPos.x += velocity.dx * base * 0.7
            newPos.y += velocity.dy * base * 0.7
        case .burst:
            newPos.x += velocity.dx * base * 1.8
            newPos.y += velocity.dy * base * 1.8
        case .spiral:
            spiralAngle += dt * 1.6
            let cx = bounds.width / 2
            let cy = bounds.height * 0.38
            let r: CGFloat = 80
            newPos = CGPoint(x: cx + cos(spiralAngle) * r, y: cy + sin(spiralAngle) * r * 0.65)
        case .evasive:
            newPos.x += velocity.dx * base * 1.2 + CGFloat.random(in: -3...3)
            newPos.y += velocity.dy * base * 1.2 + CGFloat.random(in: -3...3)
        }

        // Bounce
        if currentPhase != .spiral {
            if newPos.x < margin || newPos.x > bounds.width - margin {
                velocity = CGVector(dx: -velocity.dx * 0.92, dy: velocity.dy)
                newPos.x = max(margin, min(bounds.width - margin, newPos.x))
            }
            if newPos.y < margin || newPos.y > bounds.height * 0.72 - margin {
                velocity = CGVector(dx: velocity.dx, dy: -velocity.dy * 0.92)
                newPos.y = max(margin, min(bounds.height * 0.72 - margin, newPos.y))
            }
        }
        let final = newPos
        DispatchQueue.main.async { self.corePosition = final }
    }

    // MARK: - Hit Detection
    func tap(at point: CGPoint) {
        guard isRunning else { return }
        let dist = hypot(point.x - corePosition.x, point.y - corePosition.y)
        let eff  = (coreSize / 2) * (isShrinkMode ? 0.7 : 1.0)

        let quality: HitQuality
        if dist < eff * 0.35      { quality = .perfect }
        else if dist < eff * 0.65 { quality = .good }
        else if dist < eff * 1.0  { quality = .weak }
        else                       { quality = .miss }

        // Reaction time
        let reactionMs = 240 + Double.random(in: -80...80) // simulated for non-miss
        if quality != .miss && hitCount < 50 {
            totalReactionMs += reactionMs
            hitCount += 1
            DispatchQueue.main.async { self.lastReactionMs = reactionMs }
        }
        processHit(quality, reactionMs: reactionMs)
    }

    private func processHit(_ quality: HitQuality, reactionMs: Double) {
        let xpMult = (isShrinkMode ? 2.0 : 1.0) * (isFlowMode ? 2.0 : 1.0)
        DispatchQueue.main.async {
            self.lastHit = quality
            self.showHitFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.showHitFeedback = false }

            switch quality {
            case .perfect:
                self.combo += 1
                self.bestCombo = max(self.bestCombo, self.combo)
                self.multiplier = min(self.multiplier + 0.5, 10.0)
                self.score += Int(Double(quality.xp) * self.multiplier * xpMult)
                self.syncPercent = min(self.syncPercent + 0.1, 1.0)
            case .good:
                self.combo += 1
                self.bestCombo = max(self.bestCombo, self.combo)
                self.multiplier = min(self.multiplier + 0.2, 10.0)
                self.score += Int(Double(quality.xp) * self.multiplier * xpMult)
                self.syncPercent = min(self.syncPercent + 0.05, 1.0)
            case .weak:
                self.score += Int(Double(quality.xp) * xpMult)
                self.syncPercent = min(self.syncPercent + 0.01, 1.0)
            case .miss:
                self.combo = 0
                self.multiplier = max(1.0, self.multiplier - 1.0)
                self.syncPercent = max(0, self.syncPercent - 0.07)
            }
            if self.syncPercent >= 1.0 && !self.isFlowMode { self.triggerFlowMode() }
        }
    }

    private func triggerFlowMode() {
        isFlowMode = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isFlowMode = false
            self.syncPercent = 0.5
        }
    }

    private func triggerShrink() {
        DispatchQueue.main.async {
            self.isShrinkMode = true
            withAnimation(.spring(response: 0.3)) { self.coreSize = 77 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.3)) { self.coreSize = 110 }
                self.isShrinkMode = false
            }
        }
    }

    private func endSession() {
        displayLink?.invalidate()
        displayLink = nil
        DispatchQueue.main.async {
            self.isRunning  = false
            self.timeLeft   = 0
            self.sessionEnded = true
        }
    }

    var avgReactionSeconds: Double { hitCount > 0 ? totalReactionMs / Double(hitCount) / 1000.0 : 0 }
    var focusRating: String {
        let pct = Double(score) / 3000.0
        if pct >= 0.85 { return "A+" }
        if pct >= 0.7  { return "A"  }
        if pct >= 0.55 { return "B"  }
        if pct >= 0.4  { return "C"  }
        return "D"
    }
    var ratingLabel: String {
        switch focusRating {
        case "A+", "A": return "Excellent performance!"
        case "B":       return "Great focus!"
        case "C":       return "Keep improving!"
        default:        return "Keep practicing!"
        }
    }
    var calculatedXP: Int { DataStore.xpFormula(baseScore: score, difficulty: max(1, multiplier), streakBonus: combo > 10 ? 50 : 10) }
    deinit { displayLink?.invalidate() }
}
