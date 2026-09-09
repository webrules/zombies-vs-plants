import XCTest
@testable import MoonbridgeGarden

@MainActor
final class MobileLifecycleTests: XCTestCase {
    func testBackgroundPausesAndForegroundRequiresExplicitResume() {
        let session = MobileGameSession()
        session.game.soundEnabled = false
        session.setForeground(true)
        session.game.start(seed: 42)
        XCTAssertFalse(session.game.isPaused)
        session.setForeground(false)
        XCTAssertTrue(session.game.isPaused)
        session.setForeground(true)
        XCTAssertTrue(session.game.isPaused, "Coming back must not restart an unattended wave")
        session.game.resumeGame()
        XCTAssertFalse(session.game.isPaused)
        session.setForeground(false)
    }

    func testAudioInterruptionPausesUntilPlayerResumes() {
        let session = MobileGameSession()
        session.game.soundEnabled = false
        session.setForeground(true)
        session.game.start(seed: 42)
        session.setInterrupted(true)
        XCTAssertTrue(session.game.isPaused)
        session.setInterrupted(false)
        XCTAssertTrue(session.game.isPaused)
        session.setForeground(false)
    }

    func testTouchProjectionAtSmallPhoneAndTabletSizes() {
        for size in [CGSize(width: 430, height: 200), CGSize(width: 660, height: 270),
                     CGSize(width: 1050, height: 680)] {
            let projection = GardenProjection(size: size)
            for row in 0..<5 {
                for column in 0..<9 {
                    let point = projection.point(column: CGFloat(column) + 0.5, row: CGFloat(row) + 0.5)
                    XCTAssertEqual(projection.cell(at: point), GridCell(row: row, column: column))
                }
            }
            XCTAssertNil(projection.cell(at: .zero), "Tapping scenery must not spend sunshine")
        }
    }
}
