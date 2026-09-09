import XCTest

@MainActor
final class MoonbridgeGardenUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDifficultyPreviewMatchesStartingResources() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        defer { app.terminate() }
        for (difficulty, amount, formatted) in [("Easy", "1500", "1,500"), ("Normal", "1200", "1,200"),
                                                 ("Hard", "1000", "1,000"), ("Hell", "800", "800")] {
            app.launch()
            XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 15))
            app.buttons["difficulty-\(difficulty)"].tap()
            XCTAssertTrue(app.staticTexts["difficultySummary"].label.contains(formatted))
            app.buttons["startButton"].tap()
            XCTAssertEqual(app.staticTexts["sunshine"].value as? String, amount)
            app.terminate()
        }
    }

    func testTouchPlantingScrollingPauseAndBackground() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 15))
        app.buttons["startButton"].tap()
        let sunshine = app.staticTexts["sunshine"]
        XCTAssertTrue(sunshine.waitForExistence(timeout: 5))
        XCTAssertEqual(sunshine.value as? String, "1500")
        app.buttons["seed-PEA"].tap()

        let board = app.descendants(matching: .any)["gardenBoard"].firstMatch
        XCTAssertTrue(board.exists)
        // Shared perspective: center of row 2, column 1 (zero based).
        let row = 2.5 / 5.0
        let x = 0.47 + (1.5 / 9.0 - 0.5) * 0.78 * (0.72 + 0.28 * row)
        let y = 0.20 + 0.69 * (0.72 * row + 0.14 * row * row) / 0.86
        board.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
        XCTAssertEqual(sunshine.value as? String, "1400")

        // Scenery taps and paused taps must not spend resources.
        board.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.02)).tap()
        XCTAssertEqual(sunshine.value as? String, "1400")
        app.buttons["pauseButton"].tap()
        XCTAssertEqual(app.buttons["pauseButton"].label, "Resume")
        board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: y)).tap()
        XCTAssertEqual(sunshine.value as? String, "1400")

        let tray = app.scrollViews.firstMatch
        tray.swipeUp()
        tray.swipeUp()
        XCTAssertTrue(app.buttons["seed-GATLING"].isHittable, "The tenth seed must be reachable on a phone")
        app.buttons["seed-GATLING"].tap()
        app.buttons["pauseButton"].tap()
        XCTAssertEqual(app.buttons["pauseButton"].label, "Pause")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["pauseButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["pauseButton"].label, "Resume")
        app.buttons["pauseButton"].tap()

        XCTAssertGreaterThan(app.frame.width, app.frame.height, "The game should remain in landscape")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "iOS garden with planted pea shooter"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSoundCheckFromGuideAndMuteControl() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 15))
        app.buttons["startButton"].tap()
        app.buttons["soundButton"].tap()
        XCTAssertEqual(app.buttons["soundButton"].label, "Enable sound")
        app.buttons["How to play"].tap()
        XCTAssertTrue(app.buttons["testSoundButton"].waitForExistence(timeout: 5))
        app.buttons["testSoundButton"].tap()
        XCTAssertTrue(app.staticTexts["audioStatus"].label.contains("Audio ready"))
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["soundButton"].label, "Mute sound")
        XCTAssertEqual(app.buttons["pauseButton"].label, "Resume")
    }
}
