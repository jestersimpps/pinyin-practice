import XCTest

final class ScreenshotTourUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "missing \(identifier)")
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: button)
        _ = XCTWaiter().wait(for: [hittable], timeout: 3)
        button.tap()
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTourAllScreens() {
        snapshot("01-home")

        tap("Quick Practice")
        let field = app.textFields["Pinyin answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        sleep(1)
        snapshot("02-practice")

        field.tap()
        field.typeText("da")
        tap("Check")
        sleep(1)
        snapshot("03-practice-incorrect")

        field.typeText(XCUIKeyboardKey.delete.rawValue + XCUIKeyboardKey.delete.rawValue + "de")
        sleep(1)
        snapshot("04-practice-corrected")

        tap("Next")
        tap("Show hints")
        sleep(1)
        snapshot("05-practice-hints")
        tap("Close practice")

        app.swipeUp()
        snapshot("06-home-scrolled")
        app.swipeDown()

        tap("Chapter Practice")
        sleep(1)
        snapshot("07-chapters")
        tap("HSK 3")
        sleep(1)
        snapshot("08-chapters-hsk3")
        tap("Cancel")

        tap("Custom Practice")
        sleep(1)
        snapshot("09-custom")
        tap("Cancel")

        tap("Imprint Mode")
        tap("imprint.selectChapters")
        sleep(1)
        snapshot("10-imprint-select")
        tap("imprint.chapter1")
        tap("Done")
        tap("Start Imprint")
        sleep(3)
        snapshot("11-imprint-playing")
        tap("Stop")
        tap("Close")

        tap("Progress")
        sleep(1)
        snapshot("12-progress")
        app.swipeUp()
        snapshot("13-progress-scrolled")
        tap("Done")

        tap("Settings")
        sleep(1)
        snapshot("14-settings")
        app.swipeUp()
        snapshot("15-settings-scrolled")
        app.swipeUp()
        snapshot("16-settings-bottom")
    }
}
