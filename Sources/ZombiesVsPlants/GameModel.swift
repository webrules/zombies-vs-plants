import Foundation
import SwiftUI

enum PlantKind: String, CaseIterable, Identifiable, Sendable {
    case sunflower = "Sunflower"
    case peaShooter = "Pea Shooter"
    case wallPlant = "Wall Plant"
    case cherryBomb = "Cherry Bomb"
    case redHotPepper = "Red Hot Pepper"
    case cornCannon = "Corn Cannon"
    case charmMushroom = "Charm Mushroom"
    case icePeaShooter = "Ice Pea Shooter"

    var id: Self { self }
    var cost: Int {
        switch self {
        case .sunflower: 50
        case .peaShooter: 100
        case .wallPlant: 75
        case .cherryBomb: 150
        case .redHotPepper: 125
        case .cornCannon: 300
        case .charmMushroom: 175
        case .icePeaShooter: 150
        }
    }
    var symbol: String {
        switch self {
        case .sunflower: "SUN"
        case .peaShooter: "PEA"
        case .wallPlant: "WALL"
        case .cherryBomb: "BOOM"
        case .redHotPepper: "FIRE"
        case .cornCannon: "CORN"
        case .charmMushroom: "CHARM"
        case .icePeaShooter: "ICE"
        }
    }
}

enum ZombieKind: Sendable, Equatable {
    case regular, bucketHead, dancerSamurai, hammerGiant, iceDoctor, flameGiant, thunderShogun
    var maxHP: Double {
        switch self { case .regular: 100; case .bucketHead: 230; case .dancerSamurai: 140; case .hammerGiant: 900; case .iceDoctor: 1_500; case .flameGiant: 760; case .thunderShogun: 2_800 }
    }
    var speed: Double {
        switch self { case .regular: 0.32; case .bucketHead: 0.23; case .dancerSamurai: 0.28; case .hammerGiant: 0.145; case .iceDoctor: 0.12; case .flameGiant: 0.13; case .thunderShogun: 0.10 }
    }
    var title: String {
        switch self { case .regular: "Samurai Scout"; case .bucketHead: "Armored Samurai"; case .dancerSamurai: "Dancer Samurai"; case .hammerGiant: "Hammer Shogun"; case .iceDoctor: "Armored Ice Doctor"; case .flameGiant: "Flame Giant"; case .thunderShogun: "Thunder Shogun" }
    }
    var isBoss: Bool {
        switch self {
        case .hammerGiant, .iceDoctor, .flameGiant, .thunderShogun: true
        case .regular, .bucketHead, .dancerSamurai: false
        }
    }
    var isCharmImmune: Bool { self == .thunderShogun }
}

struct GridCell: Hashable, Sendable { let row: Int; let column: Int }

struct Plant: Identifiable, Sendable {
    let id = UUID()
    let kind: PlantKind
    var hp: Double
    var actionTimer: Double = 0
    var age: Double = 0
    var hitFlash: Double = 0
    var recoil: Double = 0
    var freezeTimer: Double = 0
    var burnTimer: Double = 0
    var charmTargetID: UUID?
}

struct Zombie: Identifiable, Sendable {
    let id = UUID()
    let kind: ZombieKind
    let row: Int
    var x: Double = 9.45
    var hp: Double
    var age: Double = 0
    var hitFlash: Double = 0
    var strikeCharge: Double = 0
    var attackCooldown: Double = 0
    var lightningTarget: GridCell?
    var charmed = false
    var charmTimer: Double = 0
    var allyAttackTimer: Double = 0
    var dancePhase: Double = 0
    var danceBoostTimer: Double = 0
    var danceCooldown: Double = 2.5
    var slowTimer: Double = 0
}

struct Pea: Identifiable, Sendable {
    let id = UUID()
    let row: Int
    var x: Double
    let icy: Bool
    var age: Double = 0
}

struct IceOrb: Identifiable, Sendable {
    let id = UUID()
    let row: Int
    var x: Double
    var age: Double = 0
}

struct CornMissile: Identifiable, Sendable {
    let id = UUID()
    let origin: GridCell
    let target: GridCell
    var progress: Double = 0
    var age: Double = 0
}

struct SunSpark: Identifiable, Sendable {
    let id = UUID()
    let cell: GridCell
    var age: Double = 0
}

struct BurstParticle: Identifiable, Sendable {
    let id = UUID()
    let cell: GridCell
    var dx: Double = 0
    var dy: Double = 0
    let vx: Double
    let vy: Double
    var age: Double = 0
    let life: Double
    let colorIndex: Int
}

struct Spawn: Sendable {
    let time: Double
    let row: Int
    let kind: ZombieKind
}

enum GamePhase: Sendable { case ready, playing, won, lost }

@MainActor
final class GameModel: ObservableObject {
    static let rows = 5
    static let columns = 9

    @Published private(set) var phase: GamePhase = .ready
    static let startingSunshine = 1_000
    static let cherryBossDamage = 300.0
    static let cherryCooldownDuration = 6.0
    static let pepperCooldownDuration = 8.0
    static let cornCannonCooldownDuration = 18.0
    static let cornBossDamage = 240.0
    static let charmMushroomCooldownDuration = 12.0
    static let icePeaCooldownDuration = 1.4
    static let icePeaDamage = 18.0
    static let icePeaSlowDuration = 3.5

    @Published private(set) var sunshine = GameModel.startingSunshine
    @Published private(set) var elapsed = 0.0
    @Published private(set) var plants: [GridCell: Plant] = [:]
    @Published private(set) var zombies: [Zombie] = []
    @Published private(set) var peas: [Pea] = []
    @Published private(set) var iceOrbs: [IceOrb] = []
    @Published private(set) var sunSparks: [SunSpark] = []
    @Published private(set) var particles: [BurstParticle] = []
    @Published private(set) var cherryCooldown = 0.0
    @Published private(set) var pepperCooldown = 0.0
    @Published private(set) var cornCooldown = 0.0
    @Published private(set) var icePeaCooldown = 0.0
    @Published private(set) var explosion: (cell: GridCell, remaining: Double)?
    @Published private(set) var pepperBurst: (row: Int, remaining: Double)?
    @Published private(set) var cornMissiles: [CornMissile] = []
    @Published private(set) var cornTarget: GridCell?
    @Published private(set) var cornBlast: (cell: GridCell, remaining: Double)?
    @Published private(set) var charmCooldown = 0.0
    @Published private(set) var charmBurst: (row: Int, remaining: Double)?
    @Published private(set) var pendingBomb: (cell: GridCell, remaining: Double)?
    @Published private(set) var waveBannerRemaining = 0.0
    @Published private(set) var screenShake = 0.0
    @Published var selectedPlant: PlantKind = .sunflower
    @Published private(set) var cornPlacementMode = true
    @Published var soundEnabled = true

    private var timer: Timer?
    private var lastTick = Date()
    private var nextSpawn = 0
    private var dancerSpawnCountsByWave = [Int](repeating: 0, count: 4)
    private let audio = AudioSynth.shared

    static let maxDancerSamuraiPerWave = 5

    let schedule: [Spawn] = [
        Spawn(time: 3, row: 2, kind: .regular),
        Spawn(time: 8, row: 0, kind: .regular),
        Spawn(time: 10, row: 1, kind: .dancerSamurai),
        Spawn(time: 13, row: 4, kind: .regular),
        Spawn(time: 15, row: 3, kind: .dancerSamurai),
        Spawn(time: 18, row: 1, kind: .regular),
        Spawn(time: 20, row: 0, kind: .dancerSamurai),
        Spawn(time: 23, row: 2, kind: .dancerSamurai),
        Spawn(time: 24, row: 3, kind: .regular),
        Spawn(time: 26, row: 4, kind: .dancerSamurai),
        Spawn(time: 29, row: 2, kind: .bucketHead),
        Spawn(time: 32, row: 4, kind: .dancerSamurai),
        Spawn(time: 33, row: 0, kind: .regular),
        Spawn(time: 35, row: 1, kind: .dancerSamurai),
        Spawn(time: 36, row: 4, kind: .regular),
        Spawn(time: 38, row: 2, kind: .dancerSamurai),
        Spawn(time: 39, row: 1, kind: .regular),
        Spawn(time: 42, row: 3, kind: .bucketHead),
        Spawn(time: 43, row: 3, kind: .dancerSamurai),
        Spawn(time: 45, row: 2, kind: .regular),
        Spawn(time: 47, row: 1, kind: .dancerSamurai),
        Spawn(time: 49, row: 0, kind: .bucketHead),
        Spawn(time: 50, row: 2, kind: .dancerSamurai),
        Spawn(time: 51, row: 4, kind: .regular),
        Spawn(time: 53, row: 1, kind: .regular),
        Spawn(time: 54, row: 1, kind: .dancerSamurai),
        Spawn(time: 55, row: 4, kind: .iceDoctor),
        Spawn(time: 56, row: 3, kind: .regular),
        Spawn(time: 57, row: 2, kind: .bucketHead),
        Spawn(time: 58, row: 3, kind: .dancerSamurai),
        Spawn(time: 59, row: 0, kind: .regular),
        Spawn(time: 60, row: 4, kind: .dancerSamurai),
        Spawn(time: 61, row: 4, kind: .bucketHead),
        Spawn(time: 62, row: 2, kind: .hammerGiant),
        Spawn(time: 63, row: 1, kind: .bucketHead),
        Spawn(time: 65, row: 3, kind: .regular),
        Spawn(time: 66, row: 0, kind: .dancerSamurai),
        Spawn(time: 66.5, row: 2, kind: .flameGiant),
        Spawn(time: 67, row: 0, kind: .thunderShogun)
    ]

    var wave: Int {
        if elapsed < 27 { return 1 }
        if elapsed < 48 { return 2 }
        return 3
    }

    var waveProgress: Double {
        switch wave {
        case 1: min(1, elapsed / 27)
        case 2: min(1, (elapsed - 27) / 21)
        default: min(1, (elapsed - 48) / 19)
        }
    }

    func start() {
        resetState()
        phase = .playing
        lastTick = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.clockTick() }
        }
    }

    func togglePause() {
        guard phase == .playing else { return }
        if timer == nil {
            lastTick = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.clockTick() }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    var isPaused: Bool { phase == .playing && timer == nil }

    func selectPlant(_ kind: PlantKind) {
        selectedPlant = kind
        if kind == .cornCannon { cornPlacementMode = true }
    }

    func plant(at cell: GridCell) {
        guard phase == .playing,
              (0..<Self.rows).contains(cell.row), (0..<Self.columns).contains(cell.column) else { return }
        if selectedPlant == .cornCannon, !cornPlacementMode,
           plants.values.contains(where: { $0.kind == .cornCannon }) {
            fireCorn(at: cell)
            return
        }
        guard plants[cell] == nil else { return }
        let kind = selectedPlant
        guard sunshine >= kind.cost else { audioIfEnabled(.error); return }
        if kind == .cherryBomb {
            guard cherryCooldown <= 0 else { audioIfEnabled(.error); return }
            sunshine -= kind.cost
            cherryCooldown = Self.cherryCooldownDuration
            pendingBomb = (cell, 0.75)
            audioIfEnabled(.fuse)
            return
        }
        if kind == .redHotPepper {
            guard pepperCooldown <= 0 else { audioIfEnabled(.error); return }
            sunshine -= kind.cost
            pepperCooldown = Self.pepperCooldownDuration
            plants[cell] = Plant(kind: kind, hp: 85, actionTimer: 0.9)
            audioIfEnabled(.pepperFuse)
            return
        }
        if kind == .cornCannon {
            sunshine -= kind.cost
            plants[cell] = Plant(kind: kind, hp: 180, actionTimer: 0)
            cornPlacementMode = false
            audioIfEnabled(.cornLoad)
            return
        }
        if kind == .charmMushroom {
            guard charmCooldown <= 0 else { audioIfEnabled(.error); return }
            sunshine -= kind.cost
            charmCooldown = Self.charmMushroomCooldownDuration
            let targetID = chooseCharmTarget(row: cell.row)
            plants[cell] = Plant(kind: kind, hp: 90, actionTimer: 1.0, charmTargetID: targetID)
            audioIfEnabled(.charmCharge)
            return
        }
        if kind == .icePeaShooter {
            guard icePeaCooldown <= 0 else { audioIfEnabled(.error); return }
            sunshine -= kind.cost
            plants[cell] = Plant(kind: kind, hp: 125, actionTimer: 0.45)
            audioIfEnabled(.plant)
            return
        }
        sunshine -= kind.cost
        let hp: Double = switch kind {
        case .sunflower: 100
        case .peaShooter: 125
        case .wallPlant: 520
        case .cherryBomb: 1
        case .redHotPepper: 85
        case .cornCannon: 180
        case .charmMushroom: 90
        case .icePeaShooter: 125
        }
        plants[cell] = Plant(kind: kind, hp: hp, actionTimer: kind == .sunflower ? 2.5 : 0.4)
        audioIfEnabled(.plant)
    }

    func removePlant(at cell: GridCell) {
        guard phase == .playing else { return }
        plants.removeValue(forKey: cell)
    }

    func advanceForTesting(_ seconds: Double, step: Double = 1.0 / 30.0) {
        var remaining = seconds
        while remaining > 0, phase == .playing {
            let dt = min(step, remaining)
            update(dt: dt)
            remaining -= dt
        }
    }

#if DEBUG
    func addZombieForTesting(_ kind: ZombieKind, row: Int, x: Double) {
        zombies.append(Zombie(kind: kind, row: row, x: x, hp: kind.maxHP))
    }

    func detonateForTesting(at cell: GridCell) { detonate(at: cell) }

    func addIceOrbForTesting(row: Int, x: Double) { iceOrbs.append(IceOrb(row: row, x: x)) }

    func addIcePeaForTesting(row: Int, x: Double) { peas.append(Pea(row: row, x: x, icy: true)) }

    func spawnScheduledForTesting(until time: Double) {
        elapsed = time
        spawnDueZombies()
    }

    @discardableResult
    func charmForTesting(row: Int) -> Bool { triggerCharm(row: row, targetID: nil) }
#endif

    private func resetState() {
        sunshine = Self.startingSunshine
        elapsed = 0
        plants = [:]
        zombies = []
        peas = []
        iceOrbs = []
        sunSparks = []
        particles = []
        cherryCooldown = 0
        pepperCooldown = 0
        cornCooldown = 0
        icePeaCooldown = 0
        charmCooldown = 0
        explosion = nil
        pendingBomb = nil
        pepperBurst = nil
        cornMissiles = []
        cornTarget = nil
        cornBlast = nil
        charmBurst = nil
        cornPlacementMode = true
        waveBannerRemaining = 2.2
        screenShake = 0
        nextSpawn = 0
        dancerSpawnCountsByWave = [Int](repeating: 0, count: 4)
    }

    private func clockTick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 0.1)
        lastTick = now
        update(dt: dt)
    }

    private func update(dt: Double) {
        let oldWave = wave
        elapsed += dt
        cherryCooldown = max(0, cherryCooldown - dt)
        pepperCooldown = max(0, pepperCooldown - dt)
        cornCooldown = max(0, cornCooldown - dt)
        icePeaCooldown = max(0, icePeaCooldown - dt)
        charmCooldown = max(0, charmCooldown - dt)
        waveBannerRemaining = max(0, waveBannerRemaining - dt)
        screenShake = max(0, screenShake - dt)
        if wave != oldWave { waveBannerRemaining = 2.2; audioIfEnabled(.wave) }
        if var boom = explosion {
            boom.remaining -= dt
            explosion = boom.remaining > 0 ? boom : nil
        }
        if var burst = pepperBurst {
            burst.remaining -= dt
            pepperBurst = burst.remaining > 0 ? burst : nil
        }
        if var blast = cornBlast {
            blast.remaining -= dt
            cornBlast = blast.remaining > 0 ? blast : nil
        }
        if var charm = charmBurst {
            charm.remaining -= dt
            charmBurst = charm.remaining > 0 ? charm : nil
        }
        if var bomb = pendingBomb {
            bomb.remaining -= dt
            if bomb.remaining <= 0 {
                pendingBomb = nil
                detonate(at: bomb.cell)
            } else { pendingBomb = bomb }
        }

        spawnDueZombies()

        for cell in Array(plants.keys) {
            guard var plant = plants[cell] else { continue }
            plant.age += dt
            plant.hitFlash = max(0, plant.hitFlash - dt)
            plant.recoil = max(0, plant.recoil - dt)
            plant.freezeTimer = max(0, plant.freezeTimer - dt)
            plant.burnTimer = max(0, plant.burnTimer - dt)
            let actionRate = plant.freezeTimer > 0 ? 0.32 : 1.0
            plant.actionTimer -= dt * actionRate
            if plant.burnTimer > 0 {
                plant.hp -= 12 * dt
                plant.hitFlash = max(plant.hitFlash, 0.06)
            }
            var consumed = false
            if plant.kind == .sunflower, plant.actionTimer <= 0 {
                sunshine += 25
                plant.actionTimer = 7
                sunSparks.append(SunSpark(cell: cell))
                audioIfEnabled(.sunshine)
            } else if plant.kind == .peaShooter, plant.actionTimer <= 0,
                      zombies.contains(where: { $0.row == cell.row && $0.x > Double(cell.column) }) {
                peas.append(Pea(row: cell.row, x: Double(cell.column) + 0.72, icy: false))
                plant.actionTimer = 1.15
                plant.recoil = 0.22
                audioIfEnabled(.shoot)
            } else if plant.kind == .icePeaShooter, plant.actionTimer <= 0,
                      zombies.contains(where: { $0.row == cell.row && $0.x > Double(cell.column) }) {
                peas.append(Pea(row: cell.row, x: Double(cell.column) + 0.72, icy: true))
                plant.actionTimer = Self.icePeaCooldownDuration
                plant.recoil = 0.22
                icePeaCooldown = Self.icePeaCooldownDuration
                audioIfEnabled(.icePeaShoot)
            } else if plant.kind == .redHotPepper, plant.actionTimer <= 0 {
                triggerPepper(row: cell.row)
                consumed = true
            } else if plant.kind == .charmMushroom, plant.actionTimer <= 0 {
                if triggerCharm(row: cell.row, targetID: plant.charmTargetID) {
                    consumed = true
                } else {
                    plant.actionTimer = 0.45
                    audioIfEnabled(.error)
                }
            }
            if consumed { plants.removeValue(forKey: cell) }
            else { plants[cell] = plant }
        }

        for index in peas.indices { peas[index].x += 3.25 * dt; peas[index].age += dt }
        var cornImpacts: [CornMissile] = []
        for index in cornMissiles.indices {
            cornMissiles[index].progress += dt / 1.15
            cornMissiles[index].age += dt
            if cornMissiles[index].progress >= 1 { cornImpacts.append(cornMissiles[index]) }
        }
        if !cornImpacts.isEmpty {
            cornMissiles.removeAll { missile in cornImpacts.contains(where: { $0.id == missile.id }) }
            for missile in cornImpacts { explodeCorn(at: missile.target) }
            if cornMissiles.isEmpty { cornTarget = nil }
        }
        for index in iceOrbs.indices { iceOrbs[index].x -= 1.35 * dt; iceOrbs[index].age += dt }
        var spentOrbs = Set<UUID>()
        for orb in iceOrbs {
            let target = plants.keys
                .filter { $0.row == orb.row && Double($0.column) <= orb.x }
                .max(by: { $0.column < $1.column })
            if let cell = target, orb.x - Double(cell.column) < 0.25, var plant = plants[cell] {
                plant.hp -= 42
                plant.freezeTimer = 3.6
                plant.hitFlash = 0.25
                if plant.hp <= 0 { plants.removeValue(forKey: cell) } else { plants[cell] = plant }
                spentOrbs.insert(orb.id)
                addIceImpactParticles(at: cell)
                audioIfEnabled(.iceHit)
            }
        }
        iceOrbs.removeAll { spentOrbs.contains($0.id) || $0.x < -0.4 }
        for index in sunSparks.indices { sunSparks[index].age += dt }
        sunSparks.removeAll { $0.age > 1.35 }
        for index in particles.indices {
            particles[index].age += dt
            particles[index].dx += particles[index].vx * dt
            particles[index].dy += particles[index].vy * dt
        }
        particles.removeAll { $0.age > $0.life }
        var hitPeas = Set<UUID>()
        for zi in zombies.indices {
            if let pea = peas.filter({ $0.row == zombies[zi].row && !hitPeas.contains($0.id) })
                .min(by: { abs($0.x - zombies[zi].x) < abs($1.x - zombies[zi].x) }),
               abs(pea.x - zombies[zi].x) < 0.14 {
                zombies[zi].hp -= pea.icy ? Self.icePeaDamage : 20
                if pea.icy {
                    zombies[zi].slowTimer = Self.icePeaSlowDuration
                    addIceImpactParticles(at: GridCell(row: zombies[zi].row, column: max(0, min(Self.columns - 1, Int(zombies[zi].x)))))
                    addSteamParticles(at: GridCell(row: zombies[zi].row, column: max(0, min(Self.columns - 1, Int(zombies[zi].x)))))
                    audioIfEnabled(.icePeaHit)
                }
                zombies[zi].hitFlash = 0.13
                hitPeas.insert(pea.id)
            }
        }
        peas.removeAll { hitPeas.contains($0.id) || $0.x > 10 }
        zombies.removeAll { $0.hp <= 0 }

        for zi in zombies.indices.reversed() {
            zombies[zi].age += dt
            zombies[zi].hitFlash = max(0, zombies[zi].hitFlash - dt)
            zombies[zi].attackCooldown = max(0, zombies[zi].attackCooldown - dt)
            zombies[zi].dancePhase += dt * (zombies[zi].charmed ? 5.5 : 7.0)
            zombies[zi].danceCooldown = max(0, zombies[zi].danceCooldown - dt)
            zombies[zi].danceBoostTimer = max(0, zombies[zi].danceBoostTimer - dt)
            zombies[zi].slowTimer = max(0, zombies[zi].slowTimer - dt)
            let row = zombies[zi].row

            if zombies[zi].kind == .dancerSamurai, !zombies[zi].charmed,
               zombies[zi].danceCooldown <= 0 {
                zombies[zi].danceBoostTimer = 1.6
                zombies[zi].danceCooldown = 7.0
                audioIfEnabled(.danceBeat)
            }

            if zombies[zi].charmed {
                zombies[zi].charmTimer -= dt
                if zombies[zi].charmTimer > 0 {
                    zombies[zi].allyAttackTimer = max(0, zombies[zi].allyAttackTimer - dt)
                    let enemyIndex = zombies.indices
                        .filter { $0 != zi && zombies[$0].row == row && !zombies[$0].charmed && zombies[$0].x > zombies[zi].x }
                        .min(by: { zombies[$0].x < zombies[$1].x })
                    if let enemyIndex, zombies[enemyIndex].x - zombies[zi].x < 0.95 {
                        zombies[enemyIndex].hp -= 34 * dt
                        zombies[enemyIndex].hitFlash = 0.1
                        if zombies[zi].allyAttackTimer <= 0 {
                            zombies[zi].allyAttackTimer = 0.5
                            audioIfEnabled(.allyStrike)
                            addImpactParticles(at: GridCell(row: row, column: max(0, min(Self.columns-1, Int(zombies[enemyIndex].x)))))
                        }
                    } else {
                        zombies[zi].x += zombies[zi].kind.speed * dt
                    }
                    continue
                } else {
                    zombies[zi].charmed = false
                    zombies[zi].charmTimer = 0
                    audioIfEnabled(.charmEnd)
                }
            }
            let target = plants.keys
                .filter { $0.row == row && Double($0.column) <= zombies[zi].x }
                .max(by: { $0.column < $1.column })
            let isBlocking = target.map { zombies[zi].x - Double($0.column) < 0.78 } ?? false

            if zombies[zi].kind == .thunderShogun {
                if zombies[zi].strikeCharge > 0 {
                    zombies[zi].strikeCharge -= dt
                    if zombies[zi].strikeCharge <= 0 {
                        if let lightningTarget = zombies[zi].lightningTarget {
                            plants.removeValue(forKey: lightningTarget)
                            addLightningParticles(at: lightningTarget)
                            screenShake = 0.52
                            audioIfEnabled(.thunderStrike)
                        }
                        zombies[zi].lightningTarget = nil
                        zombies[zi].attackCooldown = 4.5
                    }
                    continue
                } else if zombies[zi].attackCooldown <= 0,
                          let lightningTarget = plants.keys.max(by: { $0.column < $1.column }) {
                    zombies[zi].lightningTarget = lightningTarget
                    zombies[zi].strikeCharge = 2.4
                    audioIfEnabled(.thunderCharge)
                    continue
                }
            }

            if zombies[zi].kind == .iceDoctor, !isBlocking {
                if zombies[zi].strikeCharge > 0 {
                    zombies[zi].strikeCharge -= dt
                    if zombies[zi].strikeCharge <= 0 {
                        iceOrbs.append(IceOrb(row: row, x: zombies[zi].x - 0.32))
                        zombies[zi].attackCooldown = 4.8
                        audioIfEnabled(.iceLaunch)
                    }
                    continue
                } else if zombies[zi].attackCooldown <= 0 {
                    zombies[zi].strikeCharge = 1.4
                    audioIfEnabled(.iceCharge)
                    continue
                }
            }

            if let cell = target, isBlocking {
                if var plant = plants[cell] {
                    if zombies[zi].kind == .hammerGiant {
                        if zombies[zi].strikeCharge <= 0, zombies[zi].attackCooldown <= 0 {
                            zombies[zi].strikeCharge = 1.35
                            audioIfEnabled(.giantReady)
                        } else if zombies[zi].strikeCharge > 0 {
                            zombies[zi].strikeCharge -= dt
                            if zombies[zi].strikeCharge <= 0 {
                                plant.hp -= 285
                                plant.hitFlash = 0.35
                                zombies[zi].attackCooldown = 1.65
                                screenShake = 0.42
                                addImpactParticles(at: cell)
                                audioIfEnabled(.giantStrike)
                            }
                        }
                    } else if zombies[zi].kind == .iceDoctor {
                        plant.hp -= 26 * dt
                        plant.hitFlash = 0.08
                    } else if zombies[zi].kind == .flameGiant {
                        if zombies[zi].strikeCharge <= 0, zombies[zi].attackCooldown <= 0 {
                            zombies[zi].strikeCharge = 1.1
                            audioIfEnabled(.flameReady)
                        } else if zombies[zi].strikeCharge > 0 {
                            zombies[zi].strikeCharge -= dt
                            if zombies[zi].strikeCharge <= 0 {
                                plant.hp -= 85
                                plant.burnTimer = max(plant.burnTimer, 2.5)
                                plant.hitFlash = 0.35
                                zombies[zi].attackCooldown = 2.1
                                screenShake = 0.2
                                addFlameParticles(at: cell)
                                audioIfEnabled(.flameStrike)
                            }
                        }
                    } else {
                        plant.hp -= 34 * dt
                        plant.hitFlash = 0.08
                    }
                    if plant.hp <= 0 { plants.removeValue(forKey: cell) }
                    else { plants[cell] = plant }
                }
            } else {
                if zombies[zi].kind != .iceDoctor && zombies[zi].kind != .thunderShogun { zombies[zi].strikeCharge = 0 }
                let danceSpeed = zombies[zi].kind == .dancerSamurai && zombies[zi].danceBoostTimer > 0 ? 1.55 : 1.0
                let slowMultiplier = zombies[zi].slowTimer > 0 ? 0.52 : 1.0
                zombies[zi].x -= zombies[zi].kind.speed * danceSpeed * slowMultiplier * dt
            }
        }

        if zombies.contains(where: { $0.x < -0.15 }) {
            finish(.lost)
        } else if nextSpawn == schedule.count, zombies.isEmpty, elapsed > schedule.last!.time {
            finish(.won)
        }
    }

    private func spawnDueZombies() {
        while nextSpawn < schedule.count, schedule[nextSpawn].time <= elapsed {
            let spawn = schedule[nextSpawn]
            nextSpawn += 1
            if spawn.kind == .dancerSamurai {
                let spawnWave = spawn.time < 27 ? 1 : (spawn.time < 48 ? 2 : 3)
                guard dancerSpawnCountsByWave[spawnWave] < Self.maxDancerSamuraiPerWave else { continue }
                dancerSpawnCountsByWave[spawnWave] += 1
            }
            var zombie = Zombie(kind: spawn.kind, row: spawn.row, hp: spawn.kind.maxHP)
            if spawn.kind == .iceDoctor { zombie.attackCooldown = 2.6; audioIfEnabled(.doctorArrival) }
            if spawn.kind == .flameGiant { zombie.attackCooldown = 2.2; audioIfEnabled(.flameArrival) }
            if spawn.kind == .thunderShogun { zombie.attackCooldown = 3.0; audioIfEnabled(.thunderArrival) }
            zombies.append(zombie)
        }
    }

    private func detonate(at cell: GridCell) {
        explosion = (cell, 0.78)
        for index in zombies.indices.reversed() {
            let dx = abs(zombies[index].x - Double(cell.column) - 0.5)
            guard abs(zombies[index].row - cell.row) <= 1, dx < 1.75 else { continue }
            if zombies[index].kind.isBoss {
                zombies[index].hp -= Self.cherryBossDamage
                zombies[index].hitFlash = 0.45
            } else {
                zombies.remove(at: index)
            }
        }
        zombies.removeAll { $0.hp <= 0 }
        for i in 0..<34 {
            let angle = Double(i) * Double.pi * 2 / 34
            let speed = 0.65 + Double((i * 17) % 9) * 0.09
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * speed,
                                           vy: sin(angle) * speed, life: 0.55 + Double(i % 5) * 0.08,
                                           colorIndex: i % 3))
        }
        screenShake = 0.48
        audioIfEnabled(.explosion)
    }

    private func triggerPepper(row: Int) {
        pepperBurst = (row, 0.72)
        for index in zombies.indices.reversed() where zombies[index].row == row {
            if zombies[index].kind.isBoss {
                zombies[index].hp -= zombies[index].kind == .hammerGiant ? 210 : 180
                zombies[index].hitFlash = 0.42
            } else {
                zombies.remove(at: index)
            }
        }
        for column in 0..<Self.columns {
            for i in 0..<3 {
                let offset = Double(i - 1) * 0.18
                particles.append(BurstParticle(cell: GridCell(row: row, column: column), dx: 0, dy: offset,
                                               vx: 0.25 + Double(i) * 0.08, vy: -0.18 - Double(i) * 0.08,
                                               life: 0.45 + Double(i) * 0.12, colorIndex: i == 2 ? 6 : 5))
            }
        }
        screenShake = 0.28
        audioIfEnabled(.pepperBlast)
    }

    private func chooseCharmTarget(row: Int) -> UUID? {
        let sameRow = zombies.filter { $0.row == row && !$0.kind.isCharmImmune && !$0.charmed }
        if let target = sameRow.min(by: { $0.x < $1.x }) { return target.id }
        return zombies.filter { !$0.kind.isCharmImmune && !$0.charmed }.min(by: { $0.x < $1.x })?.id
    }

    private func triggerCharm(row: Int, targetID: UUID?) -> Bool {
        let selected = targetID.flatMap { id in zombies.firstIndex(where: { $0.id == id && !$0.kind.isCharmImmune && !$0.charmed }) }
            ?? zombies.firstIndex(where: { $0.row == row && !$0.kind.isCharmImmune && !$0.charmed })
            ?? zombies.firstIndex(where: { !$0.kind.isCharmImmune && !$0.charmed })
        guard let index = selected else { return false }
        zombies[index].charmed = true
        zombies[index].charmTimer = 8.0
        zombies[index].allyAttackTimer = 0.2
        charmBurst = (zombies[index].row, 0.72)
        for i in 0..<18 {
            let angle = Double(i) * Double.pi * 2 / 18
            particles.append(BurstParticle(cell: GridCell(row: zombies[index].row, column: max(0, min(Self.columns-1, Int(zombies[index].x)))), vx: cos(angle) * 0.35,
                                           vy: sin(angle) * 0.35, life: 0.5 + Double(i % 3) * 0.1, colorIndex: 9))
        }
        audioIfEnabled(.charmCast)
        return true
    }

    private func fireCorn(at target: GridCell) {
        guard cornCooldown <= 0 else { audioIfEnabled(.error); return }
        guard let cannonCell = plants.first(where: { $0.value.kind == .cornCannon })?.key else {
            cornPlacementMode = true
            return
        }
        cornCooldown = Self.cornCannonCooldownDuration
        cornTarget = target
        cornMissiles.append(CornMissile(origin: cannonCell, target: target))
        audioIfEnabled(.cornLaunch)
    }

    private func explodeCorn(at cell: GridCell) {
        cornBlast = (cell, 0.82)
        for index in zombies.indices.reversed() {
            let dx = abs(zombies[index].x - Double(cell.column) - 0.5)
            guard abs(zombies[index].row - cell.row) <= 1, dx < 1.45 else { continue }
            if zombies[index].kind.isBoss {
                zombies[index].hp -= Self.cornBossDamage
                zombies[index].hitFlash = 0.45
            } else {
                zombies.remove(at: index)
            }
        }
        zombies.removeAll { $0.hp <= 0 }
        for i in 0..<40 {
            let angle = Double(i) * Double.pi * 2 / 40
            let speed = 0.4 + Double((i * 13) % 8) * 0.07
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * speed,
                                           vy: sin(angle) * speed, life: 0.48 + Double(i % 4) * 0.1,
                                           colorIndex: i.isMultiple(of: 3) ? 0 : 1))
        }
        screenShake = 0.38
        audioIfEnabled(.cornImpact)
    }

    private func addImpactParticles(at cell: GridCell) {
        for i in 0..<12 {
            let angle = Double(i) * Double.pi * 2 / 12
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * 0.45,
                                           vy: sin(angle) * 0.45, life: 0.4, colorIndex: 3))
        }
    }

    private func addIceImpactParticles(at cell: GridCell) {
        for i in 0..<16 {
            let angle = Double(i) * Double.pi * 2 / 16
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * 0.35,
                                           vy: sin(angle) * 0.35, life: 0.55, colorIndex: 4))
        }
    }

    private func addFlameParticles(at cell: GridCell) {
        for i in 0..<18 {
            let angle = Double(i) * Double.pi * 2 / 18
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * 0.32,
                                           vy: sin(angle) * 0.32 - 0.18, life: 0.5, colorIndex: i.isMultiple(of: 2) ? 5 : 2))
        }
    }

    private func addLightningParticles(at cell: GridCell) {
        for i in 0..<28 {
            let angle = Double(i) * Double.pi * 2 / 28
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * 0.5,
                                           vy: sin(angle) * 0.5, life: 0.55 + Double(i % 3) * 0.08, colorIndex: 8))
        }
    }

    private func addSteamParticles(at cell: GridCell) {
        for i in 0..<8 {
            let angle = Double(i) * Double.pi * 2 / 8
            particles.append(BurstParticle(cell: cell, vx: cos(angle) * 0.18,
                                           vy: sin(angle) * 0.18 - 0.16, life: 0.42, colorIndex: 7))
        }
    }

    private func finish(_ result: GamePhase) {
        phase = result
        timer?.invalidate()
        timer = nil
        audioIfEnabled(result == .won ? .win : .loss)
    }

    private func audioIfEnabled(_ effect: SoundEffect) {
        if soundEnabled { audio.play(effect) }
    }
}
