import AVFoundation
import Combine

/// Singleton audio manager.
/// • Background ambient loop from the Music folder
/// • Mood-aware: plays on check-in and continues for sad moods
/// • Fades out gracefully when entering game sessions
final class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()

    // MARK: - Published state
    @Published var isPlaying: Bool = false

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var trackURLs: [URL] = []
    private var currentIndex: Int = 0
    private var fadeTimer: Timer?
    private var targetVolume: Float = 0.55

    private override init() {
        super.init()
        loadTracks()
        configureAudioSession()
    }

    // MARK: - Setup
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Session error: \(error.localizedDescription)")
        }
    }

    private func loadTracks() {
        let exts = ["mp3", "m4a", "wav", "aif", "aiff"]

        // 1) Look inside a "Music" folder-reference (copied as-is into bundle)
        if let musicDir = Bundle.main.resourceURL?.appendingPathComponent("Music"),
           FileManager.default.fileExists(atPath: musicDir.path) {
            let found = exts.flatMap { ext in
                (try? FileManager.default.contentsOfDirectory(at: musicDir,
                    includingPropertiesForKeys: nil))?.filter { $0.pathExtension.lowercased() == ext } ?? []
            }
            if !found.isEmpty {
                trackURLs = found.sorted { $0.lastPathComponent < $1.lastPathComponent }
                print("[AudioManager] Found \(trackURLs.count) track(s) in Music folder")
                return
            }
        }

        // 2) Fallback: flat bundle lookup with subdirectory hint
        trackURLs = exts.flatMap { ext in
            Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Music") ?? []
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }

        // 3) Last resort: root bundle
        if trackURLs.isEmpty {
            trackURLs = exts.flatMap { ext in
                Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }

        print("[AudioManager] Found \(trackURLs.count) track(s)")
    }

    // MARK: - Public API

    /// Start ambient loop — used on check-in page and whenever calm music is needed.
    func playBackground(volume: Float = 0.55) {
        guard !trackURLs.isEmpty else {
            print("[AudioManager] No tracks available to play")
            return
        }
        guard !isPlaying else { return }
        targetVolume = volume
        currentIndex = 0
        playTrack(at: currentIndex, volume: volume, fadeIn: true)
    }

    /// Ensure music is playing — idempotent.
    func ensurePlaying(volume: Float = 0.55) {
        if isPlaying { return }
        playBackground(volume: volume)
    }

    /// Play calming music at lower volume when user is feeling sad/overwhelmed.
    func playCalmLoop(volume: Float = 0.40) {
        if isPlaying {
            // Just lower the volume gently
            adjustVolume(to: volume, duration: 1.0)
            return
        }
        targetVolume = volume
        currentIndex = 0
        guard !trackURLs.isEmpty else { return }
        playTrack(at: currentIndex, volume: volume, fadeIn: true)
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

    /// Smoothly adjust volume.
    func adjustVolume(to target: Float, duration: Double = 1.0) {
        guard let p = player else { return }
        targetVolume = target
        let steps = Int(duration * 20)
        let step = (target - p.volume) / Float(steps)
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if abs(p.volume - target) > abs(step) {
                p.volume += step
            } else {
                p.volume = target
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        // Loop: advance to next track or replay
        currentIndex = (currentIndex + 1) % max(1, trackURLs.count)
        playTrack(at: currentIndex, volume: targetVolume, fadeIn: false)
    }

    // MARK: - Internal
    private func playTrack(at index: Int, volume: Float, fadeIn: Bool) {
        guard index < trackURLs.count else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: trackURLs[index])
            p.delegate = self
            // Always loop: if only 1 track, set infinite loop;
            // if multiple tracks, delegate handles advancement.
            p.numberOfLoops = trackURLs.count == 1 ? -1 : 0
            p.volume = fadeIn ? 0 : volume
            p.prepareToPlay()
            p.play()
            self.player    = p
            self.isPlaying = true
            if fadeIn { startFadeIn(player: p, to: volume) }
        } catch {
            print("[AudioManager] Playback error: \(error.localizedDescription)")
        }
    }

    private func startFadeIn(player p: AVAudioPlayer, to target: Float, duration: Double = 1.5) {
        let step: Float = target / Float(duration * 20)
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
            if p.volume + step < target {
                p.volume += step
            } else {
                p.volume = target
                t.invalidate()
                self?.fadeTimer = nil
            }
        }
    }
}
