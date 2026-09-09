import AVFoundation
import Foundation

enum SoundEffect: CaseIterable { case shoot, sunshine, explosion, win, loss, plant, error, fuse, wave, giantReady, giantStrike, iceCharge, iceLaunch, iceHit, icePeaShoot, icePeaHit, doctorArrival, flameArrival, flameReady, flameStrike, flamePeaHit, flameConvert, stakePlant, gatlingShoot, pepperFuse, pepperBlast, pepperHit, cornLoad, cornLaunch, cornImpact, thunderArrival, thunderCharge, thunderStrike, charmCharge, charmCast, charmEnd, allyStrike, danceBeat, tanukiGiggle }

@MainActor
final class AudioSynth {
    static let shared = AudioSynth()
    private var sounds: [SoundEffect: AVAudioPlayer] = [:]
    private var backgroundMusic: AVAudioPlayer?
    private var musicEnabled = true
    private var active = false
    private var foregroundRequested = false
    private(set) var lastError: String?

    var isMusicPlaying: Bool { backgroundMusic?.isPlaying == true }
    var preparedEffectCount: Int { sounds.count }
    func isEffectPlaying(_ effect: SoundEffect) -> Bool { sounds[effect]?.isPlaying == true }

    var diagnosticSummary: String {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute.outputs.map(\.portName).joined(separator: ", ")
        let volume = Int((session.outputVolume * 100).rounded())
        if let lastError { return "Audio unavailable: \(lastError)" }
        return "\(route.isEmpty ? "No audio output" : route) • Volume \(volume)% • \(active ? "Audio ready" : "Audio paused")"
    }

    /// Game Sound On bypasses Silent Mode; foreground lifecycle still stops playback.
    func setActive(_ value: Bool) {
        foregroundRequested = value
        if value {
            do {
                try configureSession()
                try AVAudioSession.sharedInstance().setActive(true)
                active = true
                lastError = nil
                if musicEnabled { startMusic() }
                NSLog("Moonbridge audio: %@; musicPlaying=%@", diagnosticSummary, String(isMusicPlaying))
            } catch {
                active = false
                recordError(error.localizedDescription)
            }
        } else {
            active = false
            backgroundMusic?.pause()
            for sound in sounds.values { sound.stop() }
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                NSLog("Moonbridge audio deactivation: %@", error.localizedDescription)
            }
        }
    }

    private init() {
        do { try configureSession() } catch { recordError(error.localizedDescription) }
        loadPlayers()
    }

    private func configureSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }

    func recoverAfterMediaServicesReset() {
        let shouldActivate = foregroundRequested
        active = false
        sounds.removeAll()
        backgroundMusic = nil
        do { try configureSession() } catch { recordError(error.localizedDescription) }
        loadPlayers()
        setActive(shouldActivate)
    }

    private func loadPlayers() {
        backgroundMusic = makePlayer(data: makeMarch())
        backgroundMusic?.numberOfLoops = -1
        backgroundMusic?.volume = 0.12

        sounds[.shoot] = makeSound(notes: [(520, 0.05), (300, 0.04)], volume: 0.2)
        sounds[.sunshine] = makeSound(notes: [(660, 0.08), (880, 0.12)], volume: 0.18)
        sounds[.explosion] = makeNoise(duration: 0.45, volume: 0.36)
        sounds[.win] = makeSound(notes: [(523, 0.13), (659, 0.13), (784, 0.13), (1047, 0.35)], volume: 0.22)
        sounds[.loss] = makeSound(notes: [(392, 0.18), (330, 0.18), (262, 0.42)], volume: 0.21)
        sounds[.plant] = makeSound(notes: [(240, 0.06), (360, 0.07)], volume: 0.13)
        sounds[.error] = makeSound(notes: [(145, 0.12)], volume: 0.12)
        sounds[.fuse] = makeSound(notes: [(720, 0.06), (820, 0.06), (940, 0.08)], volume: 0.13)
        sounds[.wave] = makeSound(notes: [(330, 0.11), (440, 0.11), (660, 0.2)], volume: 0.18)
        sounds[.giantReady] = makeSound(notes: [(110, 0.16), (92, 0.2)], volume: 0.24)
        sounds[.giantStrike] = makeNoise(duration: 0.24, volume: 0.42)
        sounds[.iceCharge] = makeSound(notes: [(740, 0.10), (880, 0.10), (1040, 0.15)], volume: 0.15)
        sounds[.iceLaunch] = makeSound(notes: [(1200, 0.07), (760, 0.13)], volume: 0.17)
        sounds[.iceHit] = makeSound(notes: [(1500, 0.04), (1100, 0.05), (700, 0.09)], volume: 0.18)
        sounds[.icePeaShoot] = makeSound(notes: [(860, 0.05), (1200, 0.08)], volume: 0.16)
        sounds[.icePeaHit] = makeSound(notes: [(1500, 0.04), (980, 0.08), (640, 0.12)], volume: 0.18)
        sounds[.doctorArrival] = makeSound(notes: [(196, 0.12), (247, 0.12), (370, 0.24)], volume: 0.2)
        sounds[.flameArrival] = makeSound(notes: [(120, 0.14), (170, 0.14), (245, 0.24)], volume: 0.25)
        sounds[.flameReady] = makeSound(notes: [(150, 0.13), (190, 0.16), (260, 0.22)], volume: 0.22)
        sounds[.flameStrike] = makeNoise(duration: 0.3, volume: 0.36)
        sounds[.flamePeaHit] = makeSound(notes: [(240, 0.05), (360, 0.08), (520, 0.08)], volume: 0.20)
        sounds[.flameConvert] = makeSound(notes: [(420, 0.04), (620, 0.06), (840, 0.10)], volume: 0.16)
        sounds[.stakePlant] = makeSound(notes: [(180, 0.08), (260, 0.08), (390, 0.12)], volume: 0.16)
        sounds[.gatlingShoot] = makeSound(notes: [(360, 0.035), (460, 0.035), (560, 0.045)], volume: 0.14)
        sounds[.pepperFuse] = makeSound(notes: [(180, 0.08), (220, 0.08), (280, 0.10)], volume: 0.15)
        sounds[.pepperBlast] = makeNoise(duration: 0.32, volume: 0.34)
        sounds[.pepperHit] = makeSound(notes: [(420, 0.06), (620, 0.08)], volume: 0.18)
        sounds[.cornLoad] = makeSound(notes: [(220, 0.09), (260, 0.12)], volume: 0.15)
        sounds[.cornLaunch] = makeSound(notes: [(280, 0.08), (520, 0.10), (760, 0.14)], volume: 0.22)
        sounds[.cornImpact] = makeNoise(duration: 0.38, volume: 0.4)
        sounds[.thunderArrival] = makeSound(notes: [(98, 0.18), (147, 0.18), (220, 0.28)], volume: 0.28)
        sounds[.thunderCharge] = makeSound(notes: [(140, 0.12), (196, 0.16), (330, 0.22)], volume: 0.25)
        sounds[.thunderStrike] = makeNoise(duration: 0.55, volume: 0.48)
        sounds[.charmCharge] = makeSound(notes: [(330, 0.12), (440, 0.12), (550, 0.15)], volume: 0.16)
        sounds[.charmCast] = makeSound(notes: [(880, 0.07), (1047, 0.12), (1320, 0.18)], volume: 0.18)
        sounds[.charmEnd] = makeSound(notes: [(660, 0.08), (440, 0.12)], volume: 0.12)
        sounds[.allyStrike] = makeSound(notes: [(180, 0.04), (250, 0.06)], volume: 0.14)
        sounds[.danceBeat] = makeSound(notes: [(180, 0.05), (280, 0.05), (180, 0.05)], volume: 0.14)
        sounds[.tanukiGiggle] = makeSound(notes: [(520, 0.06), (760, 0.06), (980, 0.10), (680, 0.12)], volume: 0.16)
    }

    func play(_ effect: SoundEffect) {
        guard musicEnabled, foregroundRequested else { return }
        if !active { setActive(true) }
        guard active, let player = sounds[effect] else { return }
        player.currentTime = 0
        if !player.play() { recordError("The sound effect could not start. Try Test Sound again.") }
    }

    func setBackgroundMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        if enabled && foregroundRequested {
            setActive(true)
        } else {
            backgroundMusic?.stop()
            for sound in sounds.values { sound.stop() }
        }
    }

    private func startMusic() {
        guard let backgroundMusic else {
            recordError("The soundtrack could not be loaded.")
            return
        }
        if !backgroundMusic.isPlaying, !backgroundMusic.play() {
            recordError("The soundtrack could not start. Try Test Sound again.")
        }
    }

    private func makePlayer(data: Data) -> AVAudioPlayer? {
        do {
            let player = try AVAudioPlayer(data: data)
            guard player.prepareToPlay() else {
                recordError("An audio player could not be prepared.")
                return nil
            }
            return player
        } catch {
            recordError(error.localizedDescription)
            return nil
        }
    }

    private func recordError(_ message: String) {
        lastError = message
        NSLog("Moonbridge audio error: %@", message)
    }

    private func makeMarch() -> Data {
        let rate = 11_025
        let beat = 60.0 / 112.0
        let bars = 32
        let duration = beat * 4 * Double(bars)
        let count = Int(duration * Double(rate))
        // Original minor-key military march palette: broad brass-like tones over a firm parade bass.
        let melody: [Double] = [293.66, 293.66, 349.23, 392.00, 440.00, 392.00, 349.23, 293.66]
        let bass: [Double] = [146.83, 146.83, 146.83, 110.00, 130.81, 130.81, 146.83, 146.83]
        var samples = [Int16]()
        samples.reserveCapacity(count)

        for index in 0..<count {
            let time = Double(index) / Double(rate)
            let eighth = Int(time / (beat / 2))
            let noteIndex = (eighth / 2) % melody.count
            let noteTime = time.truncatingRemainder(dividingBy: beat)
            let noteProgress = noteTime / beat
            let melodyEnvelope = min(1.0, noteProgress * 24) * pow(1 - noteProgress, 1.4)
            let bassNote = bass[(eighth / 8) % bass.count]
            let bassProgress = (time.truncatingRemainder(dividingBy: beat * 2)) / (beat * 2)
            let bassEnvelope = min(1.0, bassProgress * 12) * pow(1 - bassProgress, 1.1)
            let melodyTone = sin(2 * Double.pi * melody[noteIndex] * time)
                + 0.34 * sin(2 * Double.pi * melody[noteIndex] * 2 * time)
                + 0.12 * sin(2 * Double.pi * melody[noteIndex] * 3 * time)
            let bassTone = sin(2 * Double.pi * bassNote * time)
                + 0.22 * sin(2 * Double.pi * bassNote * 2 * time)
            let snarePhase = time.truncatingRemainder(dividingBy: beat)
            let snareEnvelope = max(0, 1 - snarePhase / 0.12)
            let snare = ((index * 1_103 % 97) < 47 ? 1.0 : -1.0) * snareEnvelope * (eighth % 2 == 1 ? 0.22 : 0.0)
            let kickEnvelope = max(0, 1 - noteTime / 0.16)
            let kick = sin(2 * Double.pi * (92 - 38 * noteTime / 0.16) * time) * kickEnvelope * (eighth % 4 == 0 ? 0.30 : 0.0)
            let value = max(-1, min(1, melodyTone * melodyEnvelope * 0.24 + bassTone * bassEnvelope * 0.30 + snare + kick))
            samples.append(Int16(value * Double(Int16.max)))
        }
        return wavData(samples: samples, rate: rate)
    }

    private func makeSound(notes: [(Double, Double)], volume: Double) -> AVAudioPlayer? {
        let rate = 22_050
        var samples: [Int16] = []
        for (frequency, duration) in notes {
            let count = Int(Double(rate) * duration)
            for i in 0..<count {
                let progress = Double(i) / Double(max(1, count))
                let envelope = min(1, progress * 18) * pow(1 - progress, 1.7)
                let value = sin(2 * Double.pi * frequency * Double(i) / Double(rate))
                samples.append(Int16(value * envelope * volume * Double(Int16.max)))
            }
        }
        return makePlayer(data: wavData(samples: samples, rate: rate))
    }

    private func makeNoise(duration: Double, volume: Double) -> AVAudioPlayer? {
        let rate = 22_050
        let count = Int(Double(rate) * duration)
        var seed: UInt64 = 0x5A17B00B
        let samples: [Int16] = (0..<count).map { i in
            seed = seed &* 6364136223846793005 &+ 1
            let noise = Double(Int32(truncatingIfNeeded: seed >> 32)) / Double(Int32.max)
            let t = Double(i) / Double(count)
            let rumble = sin(2 * Double.pi * (70 - 35 * t) * Double(i) / Double(rate))
            return Int16(max(-1, min(1, noise * 0.65 + rumble * 0.35)) * pow(1 - t, 2) * volume * Double(Int16.max))
        }
        return makePlayer(data: wavData(samples: samples, rate: rate))
    }

    private func wavData(samples: [Int16], rate: Int) -> Data {
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var v = value.littleEndian; data.append(Data(bytes: &v, count: 2)) }
        func u32(_ value: UInt32) { var v = value.littleEndian; data.append(Data(bytes: &v, count: 4)) }
        text("RIFF"); u32(UInt32(36 + samples.count * 2)); text("WAVE")
        text("fmt "); u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        text("data"); u32(UInt32(samples.count * 2))
        for sample in samples { var value = sample.littleEndian; data.append(Data(bytes: &value, count: 2)) }
        return data
    }
}
