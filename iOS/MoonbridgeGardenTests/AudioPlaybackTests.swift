import AVFoundation
import XCTest
@testable import MoonbridgeGarden

@MainActor
final class AudioPlaybackTests: XCTestCase {
    func testPlaybackCategoryAndGeneratedSoundsStartSuccessfully() {
        let audio = AudioSynth.shared
        defer { audio.setBackgroundMusicEnabled(false); audio.setActive(false) }
        audio.setBackgroundMusicEnabled(true)
        audio.setActive(true)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback,
                       "Ambient would silence the game when the iPad is in Silent Mode")
        XCTAssertTrue(AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers))
        XCTAssertEqual(audio.preparedEffectCount, SoundEffect.allCases.count)
        XCTAssertTrue(audio.isMusicPlaying)
        audio.play(.win)
        XCTAssertTrue(audio.isEffectPlaying(.win))
        XCTAssertNil(audio.lastError)
    }

    func testMuteStopsBothEffectsAndMusicAndUnmuteRestarts() {
        let audio = AudioSynth.shared
        defer { audio.setBackgroundMusicEnabled(false); audio.setActive(false) }
        audio.setBackgroundMusicEnabled(true)
        audio.setActive(true)
        audio.play(.win)
        audio.setBackgroundMusicEnabled(false)
        XCTAssertFalse(audio.isMusicPlaying)
        XCTAssertFalse(audio.isEffectPlaying(.win))
        audio.play(.win)
        XCTAssertFalse(audio.isEffectPlaying(.win))
        audio.setBackgroundMusicEnabled(true)
        XCTAssertTrue(audio.isMusicPlaying)
    }

    func testBackgroundRemainsSilentAndResetRestoresForegroundPlayback() {
        let audio = AudioSynth.shared
        defer { audio.setBackgroundMusicEnabled(false); audio.setActive(false) }
        audio.setBackgroundMusicEnabled(true)
        audio.setActive(true)
        audio.setActive(false)
        audio.play(.win)
        XCTAssertFalse(audio.isMusicPlaying)
        XCTAssertFalse(audio.isEffectPlaying(.win))
        audio.recoverAfterMediaServicesReset()
        XCTAssertFalse(audio.isMusicPlaying, "A reset must not start background audio")
        audio.setActive(true)
        XCTAssertTrue(audio.isMusicPlaying)
        audio.recoverAfterMediaServicesReset()
        XCTAssertTrue(audio.isMusicPlaying)
        XCTAssertEqual(audio.preparedEffectCount, SoundEffect.allCases.count)
        XCTAssertNil(audio.lastError)
    }
}
