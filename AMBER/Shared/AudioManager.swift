import AVFoundation
import Combine

/// Singleton audio manager. Plays background tracks from the app bundle's Music folder.
/// Start music with `AudioManager.shared.playBackground()`
/// Stop it with  `AudioManager.shared.fadeOut()`
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published state
    @Published var isPlaying: Bool = false

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var trackURLs: [URL] = []
    private var currentIndex: Int = 0
    private var fadeTimer: Timer?

    private init() {
        loadTracks()
        configureAudioSession()
    }

    // MARK: - Setup
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Session error: \(error.localizedDescription)")
        }
    }

    private func loadTracks() {
        let exts = ["mp3", "m4a", "wav", "aif", "aiff"]
        trackURLs = exts.flatMap { ext in
            Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Music") ?? []
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        print("[AudioManager] Found \(trackURLs.count) track(s)")
    }

    // MARK: - Playback
    /// Starts playing from the beginning of the track list with a fade-in.
    func playBackground(volume: Float = 0.55) {
        guard !trackURLs.isEmpty else { return }
        guard !isPlaying else { return }
        currentIndex = 0
        playTrack(at: currentIndex, targetVolume: volume, fadeIn: true)
    }

    /// Continues playing — idempotent if already playing.
    func ensurePlaying(volume: Float = 0.55) {
        if isPlaying { return }
        playBackground(volume: volume)
    }

    /// Fade out and stop.
    func fadeOut(duration: Double = 1.5) {
        guard isPlaying, let p = player else { return }
        let step: Float = p.volume / Float(duration * 20)
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if p.volume > step {
                p.volume -= step
            } else {
                p.stop()
                self.player = nil
                self.isPlaying = false
                t.invalidate()
            }
        }
    }

    /// Hard stop (no fade).
    func stop() {
        fadeTimer?.invalidate()
        player?.stop()
        player = nil
        isPlaying = false
    }

    // Advance to next track when current ends (called via delegation)
    func nextTrack() {
        guard !trackURLs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % trackURLs.count
        playTrack(at: currentIndex, targetVolume: player?.volume ?? 0.55, fadeIn: false)
    }

    // MARK: - Internal
    private func playTrack(at index: Int, targetVolume: Float, fadeIn: Bool) {
        guard index < trackURLs.count else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: trackURLs[index])
            p.numberOfLoops = trackURLs.count == 1 ? -1 : 0  // loop single track forever
            p.volume = fadeIn ? 0 : targetVolume
            p.prepareToPlay()
            p.play()
            self.player    = p
            self.isPlaying = true

            if fadeIn { startFadeIn(player: p, to: targetVolume) }

            // Auto-advance if multiple tracks
            if trackURLs.count > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + p.duration) { [weak self] in
                    self?.nextTrack()
                }
            }
        } catch {
            print("[AudioManager] Playback error: \(error.localizedDescription)")
        }
    }

    private func startFadeIn(player p: AVAudioPlayer, to target: Float, duration: Double = 1.5) {
        let step: Float = target / Float(duration * 20)
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if p.volume + step < target {
                p.volume += step
            } else {
                p.volume = target
            }
        }
    }
}
