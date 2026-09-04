import Foundation
#if os(iOS)
import AVFoundation
import AudioToolbox
#endif

/// Sound effect and audio feedback coordinator for fintech interactions.
/// Plays bundled acoustic soundscapes with fallback to iOS system sounds.
public final class SoundService: @unchecked Sendable {

    public static let shared = SoundService()

    #if os(iOS)
    private var audioPlayer: AVAudioPlayer?
    private var isAudioSessionConfigured: Bool = false
    #endif

    private init() {
        #if os(iOS)
        configureAudioSession()
        prepareAudioPlayer()
        #endif
    }

    #if os(iOS)
    private func configureAudioSession() {
        guard !isAudioSessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionConfigured = true
        } catch {
            SecureLogger.lifecycle.notice("AVAudioSession configuration notice: \(error.localizedDescription)")
        }
    }

    private func prepareAudioPlayer() {
        // Look for deposit_chime in Bundle.module (SPM) or Bundle.main (Xcode app bundle)
        let soundURL: URL? = {
            #if SWIFT_PACKAGE
            if let moduleURL = Bundle.module.url(forResource: "deposit_chime", withExtension: "wav") {
                return moduleURL
            }
            #endif
            return Bundle.main.url(forResource: "deposit_chime", withExtension: "wav")
        }()

        if let soundURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                SecureLogger.lifecycle.notice("AudioPlayer initialization fallback: \(error.localizedDescription)")
            }
        }
    }
    #endif

    /// Plays the satisfying cash/fintech deposit chime.
    public func playDepositSound() {
        #if os(iOS)
        if let player = audioPlayer {
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        } else {
            // Fallback to iOS System Tink (1057)
            AudioServicesPlaySystemSound(1057)
        }
        #endif
    }

    /// Plays a subtle UI tap tick.
    public func playTapSound() {
        #if os(iOS)
        // 1104 is iOS system tick / click sound
        AudioServicesPlaySystemSound(1104)
        #endif
    }

    /// Plays a celebration sound sequence on milestone completion.
    public func playCelebrationSound() {
        #if os(iOS)
        playDepositSound()
        // Delay a second tink for harmonic celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            AudioServicesPlaySystemSound(1057)
        }
        #endif
    }

    /// Plays a subtle delete / removal confirmation audio cue.
    public func playDeleteSound() {
        #if os(iOS)
        // 1106 is iOS keyboard delete / removal tap
        AudioServicesPlaySystemSound(1106)
        #endif
    }
}
