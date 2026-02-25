import SwiftUI

// MARK: - ViewModel
class FocusArenaViewModel: ObservableObject {
    @Published var score: Int = 0
    @Published var multiplier: Double = 1.0
    @Published var reactionMs: Int = 0
    @Published var syncPercent: Double = 0.3
    @Published var orbScale: Double = 1.0
    @Published var orbY: Double = 0
    @Published var isFlashing: Bool = false
    @Published var timeLeft: Int = 30
    @Published var isRunning: Bool = false
    @Published var sessionEnded: Bool = false

    private var baseScore = 200
    private var tapTime: Date? = nil
    private var flashStart: Date? = nil
    private var timer: Timer? = nil
    private var orbTimer: Timer? = nil

    func startSession() {
        score = 0
        multiplier = 1.0
        reactionMs = 0
        syncPercent = 0.3
        timeLeft = 30
        isRunning = true
        sessionEnded = false
        startCountdown()
        animateOrb()
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.timeLeft > 0 { self.timeLeft -= 1 }
                else {
                    t.invalidate()
                    self.orbTimer?.invalidate()
                    self.isRunning = false
                    self.sessionEnded = true
                }
            }
        }
    }

    private func animateOrb() {
        orbTimer?.invalidate()
        orbTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.0)) { self.orbY = Double.random(in: -80...80) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) { self.isFlashing = true }
                    self.flashStart = Date()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation { self.isFlashing = false }
                        self.flashStart = nil
                    }
                }
            }
        }
    }

    func tap() {
        guard isRunning else { return }
        let now = Date()
        if let fs = flashStart {
            let elapsed = now.timeIntervalSince(fs) * 1000
            let ms = Int(elapsed)
            reactionMs = ms
            let perfect = ms < 300
            if perfect {
                multiplier = min(multiplier + 0.5, 8.0)
                let xp = Int(Double(baseScore) * multiplier)
                score += xp
                syncPercent = min(syncPercent + 0.05, 1.0)
            } else {
                multiplier = max(1.0, multiplier - 0.5)
            }
        }
    }

    var calculatedXP: Int { DataStore.xpFormula(baseScore: score, difficulty: multiplier, streakBonus: 10) }
    deinit { timer?.invalidate(); orbTimer?.invalidate() }
}
