import XCTest
@testable import MoonbridgeGarden

@MainActor
final class DifficultySyncTests: XCTestCase {
    func testScheduledBossesUseDifficultyHealthForBombDurability() throws {
        for difficulty in Difficulty.allCases {
            for kind in [ZombieKind.hammerGiant, .iceDoctor] {
                let game = GameModel()
                game.soundEnabled = false
                game.selectedDifficulty = difficulty
                game.spawnScheduledForTesting(until: 70)
                let boss = try XCTUnwrap(game.zombies.first { $0.kind == kind })
                let fullHP = kind.maxHP * difficulty.enemyHealthMultiplier
                XCTAssertEqual(boss.hp, fullHP, accuracy: 0.01)
                let hits = Int(ceil(fullHP / GameModel.cherryBossDamage))
                for hit in 1...hits {
                    game.detonateForTesting(at: GridCell(row: boss.row, column: 8))
                    let surviving = game.zombies.first { $0.id == boss.id }
                    if hit < hits {
                        XCTAssertEqual(try XCTUnwrap(surviving).hp,
                                       fullHP - Double(hit) * GameModel.cherryBossDamage, accuracy: 0.01)
                    } else {
                        XCTAssertNil(surviving)
                    }
                }
            }
        }
    }

    func testHardFrostReducesIncomeAndDelaysSunflowerActions() throws {
        let game = GameModel()
        game.soundEnabled = false
        game.selectedDifficulty = .hard
        game.start(seed: 42)
        game.pauseGame()
        game.activateTerrainHazardForTesting(wave: 2)
        let lane = try XCTUnwrap(game.terrainHazard?.lanes.first)
        game.selectPlant(.sunflower)
        game.plant(at: GridCell(row: lane, column: 0))
        game.advanceForTesting(2.6)
        XCTAssertEqual(game.sunshine, 950, "Frost delays the usual 2.5-second first production")
        game.advanceForTesting(1.3)
        XCTAssertEqual(game.sunshine, 967, "25 base × 0.8 Hard × 0.85 frost = 17")
    }
}
