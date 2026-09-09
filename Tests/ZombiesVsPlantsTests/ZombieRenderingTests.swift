import SwiftUI
import XCTest
@testable import ZombiesVsPlants

@MainActor
final class ZombieRenderingTests: XCTestCase {
    private let kinds: [ZombieKind] = [.regular, .bucketHead, .dancerSamurai, .hammerGiant,
                                        .iceDoctor, .flameGiant, .thunderShogun]

    func testEngagedAndChargingPosesPlantTheirFeet() {
        for kind in kinds {
            var zombie = Zombie(kind: kind, row: 0, hp: kind.maxHP, age: 1.7, dancePhase: 1.2)
            let walking = ZombiePose(zombie: zombie, engaged: false)
            XCTAssertNotEqual(walking.stride, 0)
            let attacking = ZombiePose(zombie: zombie, engaged: true)
            XCTAssertEqual(attacking.stride, 0)
            XCTAssertEqual(attacking.lift, 0)
            XCTAssertEqual(attacking.bob, 0)
            XCTAssertGreaterThan(attacking.reach, 0)
            if kind.isBoss {
                zombie.strikeCharge = 0.5
                let charging = ZombiePose(zombie: zombie, engaged: false)
                XCTAssertEqual(charging.stride, 0)
                XCTAssertEqual(charging.reach, 0)
                XCTAssertGreaterThan(charging.charge, 0)
                XCTAssertLessThan(charging.charge, 1)
                zombie.charmed = true
                let ally = ZombiePose(zombie: zombie, engaged: false)
                XCTAssertEqual(ally.charge, 0)
                XCTAssertNotEqual(ally.stride, 0)
            }
            zombie.charmed = true
            XCTAssertEqual(ZombiePose(zombie: zombie, engaged: true).facing, -walking.facing)
        }
    }

    func testEveryEnemyHasDistinctDeterministicArtworkAndVisibleCombatStates() throws {
        var portraits: Set<Data> = []
        for kind in kinds {
            var zombie = Zombie(kind: kind, row: 0, hp: kind.maxHP, age: 2.3, dancePhase: 1.2)
            let normal = try portrait(zombie)
            XCTAssertEqual(normal, try portrait(zombie), "Texture should not flicker between frames")
            XCTAssertNotEqual(normal, try portrait(zombie, engaged: true), "Attacks should use a planted stance")
            portraits.insert(normal)
            zombie.hitFlash = 0.13
            XCTAssertNotEqual(normal, try portrait(zombie))
            zombie.hitFlash = 0
            zombie.slowTimer = 2
            XCTAssertNotEqual(normal, try portrait(zombie), "Frost must remain visible")
            zombie.slowTimer = 0
            zombie.burnTimer = 1
            XCTAssertNotEqual(normal, try portrait(zombie), "Burn must remain visible")
            zombie.burnTimer = 0
            if !kind.isCharmImmune {
                zombie.charmed = true
                XCTAssertNotEqual(normal, try portrait(zombie), "Allies face the other direction")
                zombie.charmed = false
            }
            zombie.age += 0.25
            zombie.dancePhase += 1
            let walking = try portrait(zombie)
            XCTAssertNotEqual(normal, walking, "Walk should animate limbs")
            if kind.isBoss {
                zombie.strikeCharge = 0.4
                XCTAssertNotEqual(walking, try portrait(zombie), "Charge should change the pose and show a warning")
            }
        }
        XCTAssertEqual(portraits.count, kinds.count)
    }

    func testEnemyContactSheetAtCloseupAndGameplaySizes() throws {
        let view = Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(red: 0.25, green: 0.32, blue: 0.23)))
            for row in 0..<3 {
                for (column, kind) in self.kinds.enumerated() {
                    var zombie = Zombie(kind: kind, row: 0, hp: kind.maxHP * 0.7, age: 2.3, dancePhase: 1.2)
                    if row == 1 {
                        zombie.strikeCharge = kind.isBoss ? 0.3 : 0
                        zombie.burnTimer = kind.isBoss ? 0 : 1
                    }
                    if row == 2 {
                        zombie.charmed = !kind.isCharmImmune
                        zombie.slowTimer = 2
                    }
                    let ground = CGPoint(x: CGFloat(column) * 215 + 107, y: CGFloat(row) * 370 + 310)
                    ZombieRenderer.draw(context: &context, zombie: zombie, ground: ground,
                                        scale: row == 2 ? 0.65 : 1.3, engaged: row == 1)
                    context.draw(Text(kind.title).font(.system(size: 11)).foregroundStyle(.white),
                                 at: CGPoint(x: ground.x, y: ground.y + 46))
                }
            }
        }.frame(width: 1505, height: 1110)
        let image = try XCTUnwrap(ImageRenderer(content: view).cgImage)
        XCTAssertEqual(image.width, 1505)
        if let directory = ProcessInfo.processInfo.environment["ZOMBIE_RENDER_PREVIEW_DIR"] {
            let data = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("zombie-contact-sheet.png"))
        }
    }

    private func portrait(_ zombie: Zombie, engaged: Bool = false) throws -> Data {
        let view = Canvas { context, _ in
            ZombieRenderer.draw(context: &context, zombie: zombie, ground: CGPoint(x: 120, y: 250),
                                scale: 1, engaged: engaged)
        }.frame(width: 240, height: 280)
        let image = try XCTUnwrap(ImageRenderer(content: view).cgImage)
        return try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
    }
}
