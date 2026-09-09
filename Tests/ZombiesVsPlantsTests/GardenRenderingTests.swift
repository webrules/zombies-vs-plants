import SwiftUI
import XCTest
@testable import ZombiesVsPlants

@MainActor
final class GardenRenderingTests: XCTestCase {
    func testProceduralGardenRendersPopulatedSceneAtTwoSizes() throws {
        let game = GameModel()
        game.soundEnabled = false
        game.start(seed: 42)
        game.pauseGame()
        game.advanceForTesting(2.3)
        let plants: [PlantKind] = [.sunflower, .peaShooter, .wallPlant, .icePeaShooter, .flameStake,
                                   .gatlingPeaShooter, .cornCannon, .charmMushroom]
        for (i, kind) in plants.enumerated() {
            game.selectPlant(kind)
            game.plant(at: GridCell(row: i % 5, column: i / 5 + 1))
        }
        for (i, kind) in [ZombieKind.regular, .bucketHead, .dancerSamurai, .hammerGiant,
                          .iceDoctor, .flameGiant, .thunderShogun].enumerated() {
            game.addZombieForTesting(kind, row: i % 5, x: i < 5 ? 6 : 8)
        }
        game.advanceForTesting(1)
        game.selectPlant(.redHotPepper)
        game.plant(at: GridCell(row: 4, column: 3))
        game.selectPlant(.cherryBomb)
        game.plant(at: GridCell(row: 3, column: 3))
        game.advanceForTesting(0.3)
        game.addPeaForTesting(row: 0, x: 4)
        game.addIceOrbForTesting(row: 3, x: 4)
        game.triggerTanukiForTesting()
        game.resumeGame()
        defer { game.pauseGame() }
        for size in [CGSize(width: 700, height: 440), CGSize(width: 1200, height: 680)] {
            let view = Canvas { context, canvasSize in
                LawnRenderer.draw(context: &context, size: canvasSize, game: game)
            }.frame(width: size.width, height: size.height)
            let renderer = ImageRenderer(content: view)
            let image = try XCTUnwrap(renderer.cgImage)
            XCTAssertEqual(image.width, Int(size.width))
            XCTAssertEqual(image.height, Int(size.height))
            let bitmap = NSBitmapImageRep(cgImage: image)
            XCTAssertGreaterThan(try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).count, 10_000)
            if ProcessInfo.processInfo.environment["GARDEN_RENDER_PREVIEW"] == "1" {
                let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                try data.write(to: URL(fileURLWithPath: ".build/garden-\(Int(size.width)).png"))
            }
        }
    }
}
