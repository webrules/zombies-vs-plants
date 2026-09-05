import AppKit
import Foundation

enum SoundEffect: CaseIterable { case shoot, sunshine, explosion, win, loss, plant, error, fuse, wave, giantReady, giantStrike, iceCharge, iceLaunch, iceHit, doctorArrival, pepperFuse, pepperBlast, pepperHit, cornLoad, cornLaunch, cornImpact, thunderArrival, thunderCharge, thunderStrike }

@MainActor
final class AudioSynth {
    static let shared = AudioSynth()
    private var sounds: [SoundEffect: NSSound] = [:]

    private init() {
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
        sounds[.doctorArrival] = makeSound(notes: [(196, 0.12), (247, 0.12), (370, 0.24)], volume: 0.2)
        sounds[.pepperFuse] = makeSound(notes: [(180, 0.08), (220, 0.08), (280, 0.10)], volume: 0.15)
        sounds[.pepperBlast] = makeNoise(duration: 0.32, volume: 0.34)
        sounds[.pepperHit] = makeSound(notes: [(420, 0.06), (620, 0.08)], volume: 0.18)
        sounds[.cornLoad] = makeSound(notes: [(220, 0.09), (260, 0.12)], volume: 0.15)
        sounds[.cornLaunch] = makeSound(notes: [(280, 0.08), (520, 0.10), (760, 0.14)], volume: 0.22)
        sounds[.cornImpact] = makeNoise(duration: 0.38, volume: 0.4)
        sounds[.thunderArrival] = makeSound(notes: [(98, 0.18), (147, 0.18), (220, 0.28)], volume: 0.28)
        sounds[.thunderCharge] = makeSound(notes: [(140, 0.12), (196, 0.16), (330, 0.22)], volume: 0.25)
        sounds[.thunderStrike] = makeNoise(duration: 0.55, volume: 0.48)
    }

    func play(_ effect: SoundEffect) {
        sounds[effect]?.stop()
        sounds[effect]?.play()
    }

    private func makeSound(notes: [(Double, Double)], volume: Double) -> NSSound? {
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
        return NSSound(data: wavData(samples: samples, rate: rate))
    }

    private func makeNoise(duration: Double, volume: Double) -> NSSound? {
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
        return NSSound(data: wavData(samples: samples, rate: rate))
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
