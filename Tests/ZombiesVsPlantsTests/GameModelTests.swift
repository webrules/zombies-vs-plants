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
        XCTAssertEqual(game.schedule.count, 23)
        XCTAssertTrue(game.schedule.contains { $0.kind == .regular })
        XCTAssertTrue(game.schedule.contains { $0.kind == .bucketHead })
        XCTAssertTrue(game.schedule.contains { $0.kind == .hammerGiant })
        XCTAssertTrue(game.schedule.contains { $0.kind == .iceDoctor })
        XCTAssertTrue(game.schedule.contains { $0.kind == .thunderShogun })
        XCTAssertGreaterThan(game.schedule.filter { $0.time >= 48 }.count,
                             game.schedule.filter { $0.time < 27 }.count)
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
}
