import XCTest
@testable import ZombiesVsPlants

@MainActor
final class GameModelTests: XCTestCase {
    func testPlantingSpendsSunshineAndOccupiesCell() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.selectedPlant = .peaShooter
        game.plant(at: GridCell(row: 2, column: 1))
        XCTAssertEqual(game.sunshine, 900)
        XCTAssertEqual(game.plants[GridCell(row: 2, column: 1)]?.kind, .peaShooter)
    }

    func testCannotPlantTwiceInOneCell() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        let cell = GridCell(row: 0, column: 0)
        game.selectedPlant = .sunflower
        game.plant(at: cell)
        game.plant(at: cell)
        XCTAssertEqual(game.sunshine, 950)
        XCTAssertEqual(game.plants.count, 1)
    }

    func testWavesEscalateAndContainBothEnemyTypes() {
        let game = GameModel()
        XCTAssertEqual(game.schedule.count, 39)
        XCTAssertTrue(game.schedule.contains { $0.kind == .regular })
        XCTAssertTrue(game.schedule.contains { $0.kind == .bucketHead })
        XCTAssertTrue(game.schedule.contains { $0.kind == .hammerGiant })
        XCTAssertTrue(game.schedule.contains { $0.kind == .iceDoctor })
        XCTAssertTrue(game.schedule.contains { $0.kind == .flameGiant })
        XCTAssertTrue(game.schedule.contains { $0.kind == .thunderShogun })
        XCTAssertTrue(game.schedule.contains { $0.kind == .dancerSamurai })
        let dancers = game.schedule.filter { $0.kind == .dancerSamurai }
        XCTAssertEqual(dancers.count, GameModel.maxDancerSamuraiPerWave * 3)
        XCTAssertEqual(dancers.filter { $0.time < 27 }.count, GameModel.maxDancerSamuraiPerWave)
        XCTAssertEqual(dancers.filter { $0.time >= 27 && $0.time < 48 }.count, GameModel.maxDancerSamuraiPerWave)
        XCTAssertEqual(dancers.filter { $0.time >= 48 }.count, GameModel.maxDancerSamuraiPerWave)
        XCTAssertGreaterThan(game.schedule.filter { $0.time >= 48 }.count,
                             game.schedule.filter { $0.time < 27 }.count)
    }

    func testDancerSamuraiGenerationAllowsEachWaveAndCapsEachAtFive() {
        let firstWave = GameModel()
        firstWave.soundEnabled = false
        firstWave.spawnScheduledForTesting(until: 26.9)
        XCTAssertEqual(firstWave.zombies.filter { $0.kind == .dancerSamurai }.count, 5)

        let secondWave = GameModel()
        secondWave.soundEnabled = false
        secondWave.spawnScheduledForTesting(until: 47.9)
        XCTAssertEqual(secondWave.wave, 2)
        XCTAssertEqual(secondWave.zombies.filter { $0.kind == .dancerSamurai }.count, 10)

        let fullLevel = GameModel()
        fullLevel.soundEnabled = false
        fullLevel.spawnScheduledForTesting(until: 70)
        XCTAssertEqual(fullLevel.zombies.filter { $0.kind == .dancerSamurai }.count, 15)
    }

    func testHammerGiantIsSlowAndBossTough() {
        XCTAssertGreaterThan(ZombieKind.hammerGiant.maxHP, ZombieKind.bucketHead.maxHP * 3)
        XCTAssertLessThan(ZombieKind.hammerGiant.speed, ZombieKind.bucketHead.speed)
        XCTAssertEqual(ZombieKind.hammerGiant.title, "Hammer Shogun")
    }

    func testHammerStrikeIsTelegraphedBeforeHeavyDamage() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.selectedPlant = .wallPlant
        let cell = GridCell(row: 2, column: 1)
        game.plant(at: cell)
        game.addZombieForTesting(.hammerGiant, row: 2, x: 1.70)

        game.advanceForTesting(0.55)
        XCTAssertEqual(game.plants[cell]?.hp, 520, "The visible wind-up must give the player reaction time")
        XCTAssertGreaterThan(game.zombies.first?.strikeCharge ?? 0, 0)

        game.advanceForTesting(1.0)
        XCTAssertEqual(game.plants[cell]?.hp ?? -1, 235, accuracy: 0.01)
    }

    func testShogunSurvivesTwoDirectBombsAndFallsToThird() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.hammerGiant, row: 2, x: 2.5)
        let cell = GridCell(row: 2, column: 2)
        game.detonateForTesting(at: cell)
        game.detonateForTesting(at: cell)
        XCTAssertEqual(game.zombies.first?.hp ?? -1, 300, accuracy: 0.01)
        game.detonateForTesting(at: cell)
        XCTAssertTrue(game.zombies.isEmpty)
    }

    func testIceDoctorTakesFiveDirectBombs() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.iceDoctor, row: 3, x: 3.5)
        let cell = GridCell(row: 3, column: 3)
        for _ in 0..<4 { game.detonateForTesting(at: cell) }
        XCTAssertEqual(game.zombies.first?.hp ?? -1, 300, accuracy: 0.01)
        game.detonateForTesting(at: cell)
        XCTAssertTrue(game.zombies.isEmpty)
    }

    func testIceOrbDamagesAndSlowsPlant() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.selectedPlant = .wallPlant
        let cell = GridCell(row: 1, column: 1)
        game.plant(at: cell)
        game.addIceOrbForTesting(row: 1, x: 1.2)
        game.advanceForTesting(0.1)
        XCTAssertEqual(game.plants[cell]?.hp ?? -1, 478, accuracy: 0.01)
        XCTAssertGreaterThan(game.plants[cell]?.freezeTimer ?? 0, 3)
        XCTAssertTrue(game.iceOrbs.isEmpty)
    }

    func testIcePeaPlacementCostsSunshineAndFiresAVisibleProjectile() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.regular, row: 2, x: 4)
        game.selectPlant(.icePeaShooter)
        let cell = GridCell(row: 2, column: 1)
        game.plant(at: cell)
        XCTAssertEqual(game.sunshine, 850)
        XCTAssertEqual(game.plants[cell]?.kind, .icePeaShooter)
        game.advanceForTesting(0.5)
        XCTAssertTrue(game.peas.contains { $0.icy }, "Ice Pea should create a distinct projectile")
        game.advanceForTesting(0.7)
        XCTAssertLessThan(game.zombies.first?.hp ?? 100, 100)
        XCTAssertGreaterThan(game.zombies.first?.slowTimer ?? 0, 3)
        XCTAssertGreaterThan(game.icePeaCooldown, 0)
        XCTAssertLessThan(game.icePeaCooldown, GameModel.icePeaCooldownDuration)
    }

    func testIcePeaSlowAppliesAndRefreshesOnAllEnemyKindsIncludingBosses() {
        let kinds: [ZombieKind] = [.regular, .bucketHead, .dancerSamurai, .hammerGiant, .iceDoctor, .flameGiant, .thunderShogun]
        for kind in kinds {
            let game = GameModel()
            game.soundEnabled = false
            game.start()
            game.togglePause()
            game.addZombieForTesting(kind, row: 0, x: 3)
            game.addIcePeaForTesting(row: 0, x: 2.9)
            game.advanceForTesting(0.1)
            XCTAssertGreaterThan(game.zombies.first?.slowTimer ?? 0, 3, "Ice Pea should slow \(kind.title)")
            game.addIcePeaForTesting(row: 0, x: 2.9)
            game.advanceForTesting(0.1)
            XCTAssertGreaterThan(game.zombies.first?.slowTimer ?? 0, 3.2, "A second hit should refresh \(kind.title)'s slow")
        }
    }

    func testFlameGiantTelegraphsBurnsAndIsCharmable() {
        XCTAssertEqual(ZombieKind.flameGiant.title, "Flame Giant")
        XCTAssertLessThan(ZombieKind.flameGiant.speed, ZombieKind.bucketHead.speed)
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        let cell = GridCell(row: 2, column: 1)
        game.selectPlant(.wallPlant)
        game.plant(at: cell)
        game.addZombieForTesting(.flameGiant, row: 2, x: 1.7)
        game.advanceForTesting(0.5)
        XCTAssertEqual(game.plants[cell]?.hp ?? -1, 520, accuracy: 0.01)
        XCTAssertGreaterThan(game.zombies.first?.strikeCharge ?? 0, 0)
        game.advanceForTesting(0.7)
        XCTAssertLessThan(game.plants[cell]?.hp ?? 520, 435)
        XCTAssertGreaterThan(game.plants[cell]?.burnTimer ?? 0, 2)

        let charmGame = GameModel()
        charmGame.soundEnabled = false
        charmGame.start()
        charmGame.togglePause()
        charmGame.addZombieForTesting(.flameGiant, row: 1, x: 4)
        XCTAssertTrue(charmGame.charmForTesting(row: 1))
        XCTAssertTrue(charmGame.zombies.first?.charmed ?? false)
    }

    func testIceDoctorTelegraphsBeforeLaunchingOrb() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.iceDoctor, row: 4, x: 6)

        game.advanceForTesting(0.5)
        XCTAssertTrue(game.iceOrbs.isEmpty)
        XCTAssertGreaterThan(game.zombies.first?.strikeCharge ?? 0, 0)

        game.advanceForTesting(1.1)
        XCTAssertEqual(game.iceOrbs.count, 1)
    }

    func testNewGameStartsWithOneThousandSunshine() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        XCTAssertEqual(game.sunshine, 1_000)
    }

    func testRedHotPepperClearsOrdinaryLaneAndDamagesBosses() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.regular, row: 2, x: 5)
        game.addZombieForTesting(.hammerGiant, row: 2, x: 5)
        game.addZombieForTesting(.iceDoctor, row: 2, x: 5)
        game.selectedPlant = .redHotPepper
        let cell = GridCell(row: 2, column: 0)
        game.plant(at: cell)
        XCTAssertEqual(game.sunshine, 875)
        game.advanceForTesting(0.65)
        XCTAssertTrue(game.zombies.contains { $0.kind == .regular }, "The warning phase should be readable")
        game.advanceForTesting(0.45)

        XCTAssertFalse(game.zombies.contains { $0.kind == .regular })
        XCTAssertEqual(game.zombies.first(where: { $0.kind == .hammerGiant })?.hp ?? -1, 690, accuracy: 0.01)
        XCTAssertEqual(game.zombies.first(where: { $0.kind == .iceDoctor })?.hp ?? -1, 1_320, accuracy: 0.01)
        XCTAssertNotNil(game.pepperBurst)
        game.plant(at: GridCell(row: 2, column: 1))
        XCTAssertNil(game.plants[GridCell(row: 2, column: 1)], "Pepper cooldown should prevent immediate replanting")
    }

    func testCornCannonPlacesSelectsTargetAndDamagesArea() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.regular, row: 2, x: 4)
        game.addZombieForTesting(.hammerGiant, row: 2, x: 4)
        game.addZombieForTesting(.bucketHead, row: 3, x: 4)
        game.selectPlant(.cornCannon)
        let cannonCell = GridCell(row: 2, column: 1)
        let target = GridCell(row: 2, column: 3)
        game.plant(at: cannonCell)
        XCTAssertFalse(game.cornPlacementMode)
        XCTAssertEqual(game.sunshine, 700)

        game.plant(at: target)
        XCTAssertEqual(game.cornMissiles.count, 1)
        XCTAssertEqual(game.cornTarget, target)
        XCTAssertEqual(game.cornCooldown, GameModel.cornCannonCooldownDuration, accuracy: 0.01)
        game.advanceForTesting(0.4)
        XCTAssertTrue(game.zombies.contains { $0.kind == .regular }, "The missile must have visible flight time")
        game.advanceForTesting(0.9)

        XCTAssertFalse(game.zombies.contains { $0.kind == .regular })
        XCTAssertFalse(game.zombies.contains { $0.kind == .bucketHead }, "The blast should affect its neighboring row")
        XCTAssertEqual(game.zombies.first(where: { $0.kind == .hammerGiant })?.hp ?? -1, 660, accuracy: 0.01)
        XCTAssertNotNil(game.cornBlast)
        game.plant(at: GridCell(row: 2, column: 4))
        XCTAssertEqual(game.cornMissiles.count, 0, "Long cannon cooldown should prevent an immediate second shot")
    }

    func testThunderShogunTelegraphsAndDestroysPlantRegardlessOfHealth() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.selectedPlant = .wallPlant
        let cell = GridCell(row: 0, column: 2)
        game.plant(at: cell)
        game.addZombieForTesting(.thunderShogun, row: 0, x: 5)
        XCTAssertGreaterThan(ZombieKind.thunderShogun.maxHP, ZombieKind.iceDoctor.maxHP)

        game.advanceForTesting(0.5)
        XCTAssertGreaterThan(game.zombies.first?.strikeCharge ?? 0, 0)
        XCTAssertEqual(game.zombies.first?.lightningTarget, cell)
        XCTAssertEqual(game.plants[cell]?.hp ?? -1, 520, "The warning phase must give the player time to react")
        game.advanceForTesting(2.1)
        XCTAssertNil(game.plants[cell], "Lightning ignores plant HP and removes the marked plant")
    }

    func testCharmMushroomTargetsChargesConvertsAndCooldowns() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.regular, row: 2, x: 4)
        game.addZombieForTesting(.bucketHead, row: 2, x: 5)
        game.addZombieForTesting(.hammerGiant, row: 2, x: 6)
        game.selectPlant(.charmMushroom)
        let mushroomCell = GridCell(row: 2, column: 1)
        game.plant(at: mushroomCell)
        XCTAssertEqual(game.sunshine, 825)
        XCTAssertEqual(game.charmCooldown, GameModel.charmMushroomCooldownDuration, accuracy: 0.01)
        XCTAssertNotNil(game.plants[mushroomCell]?.charmTargetID)

        game.advanceForTesting(0.7)
        XCTAssertFalse(game.zombies.first?.charmed ?? true, "The mushroom needs a readable charge phase")
        game.advanceForTesting(0.45)
        XCTAssertTrue(game.zombies.contains { $0.charmed && $0.kind == .regular })
        XCTAssertNil(game.plants[mushroomCell])
        XCTAssertEqual(game.zombies.first(where: { $0.kind == .hammerGiant })?.hp ?? -1, 900, accuracy: 0.01, "Bosses are immune to Charm Mushroom")

        game.advanceForTesting(0.6)
        XCTAssertLessThan(game.zombies.first(where: { $0.kind == .bucketHead })?.hp ?? 230, 230, "A charmed samurai should attack an enemy")
        game.plant(at: GridCell(row: 2, column: 0))
        XCTAssertNil(game.plants[GridCell(row: 2, column: 0)], "Charm cooldown should prevent immediate replanting")
    }

    func testDancerSamuraiGetsAReadableSpeedBurstAndCanBeCharmed() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.dancerSamurai, row: 1, x: 7)
        XCTAssertEqual(ZombieKind.dancerSamurai.title, "Dancer Samurai")
        game.advanceForTesting(2.7)
        XCTAssertGreaterThan(game.zombies.first?.danceBoostTimer ?? 0, 0)
        game.selectPlant(.charmMushroom)
        game.plant(at: GridCell(row: 1, column: 1))
        game.advanceForTesting(1.1)
        XCTAssertTrue(game.zombies.first?.charmed ?? false, "Charm Mushroom must affect the Dancer Samurai")
    }

    func testCharmAffectsEarlierBossesButThunderShogunIsImmune() {
        let game = GameModel()
        game.soundEnabled = false
        game.start()
        game.togglePause()
        game.addZombieForTesting(.hammerGiant, row: 2, x: 4)
        game.addZombieForTesting(.iceDoctor, row: 2, x: 5)
        game.addZombieForTesting(.dancerSamurai, row: 2, x: 6)
        game.addZombieForTesting(.flameGiant, row: 2, x: 6.5)
        game.addZombieForTesting(.thunderShogun, row: 2, x: 7)

        XCTAssertTrue(game.charmForTesting(row: 2))
        XCTAssertTrue(game.zombies.first(where: { $0.kind == .hammerGiant })?.charmed ?? false)
        XCTAssertTrue(game.charmForTesting(row: 2))
        XCTAssertTrue(game.zombies.first(where: { $0.kind == .iceDoctor })?.charmed ?? false)
        XCTAssertTrue(game.charmForTesting(row: 2))
        XCTAssertTrue(game.zombies.first(where: { $0.kind == .dancerSamurai })?.charmed ?? false)
        XCTAssertTrue(game.charmForTesting(row: 2))
        XCTAssertTrue(game.zombies.first(where: { $0.kind == .flameGiant })?.charmed ?? false)
        XCTAssertFalse(game.zombies.first(where: { $0.kind == .thunderShogun })?.charmed ?? true)
    }
}
