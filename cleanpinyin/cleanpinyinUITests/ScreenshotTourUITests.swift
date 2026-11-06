import XCTest

final class ScreenshotTourUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTourAllScreens() {
        snapshot("01-home")

        app.buttons["Quick Practice"].tap()
        let field = app.textFields["Pinyin answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        sleep(1)
        snapshot("02-practice")

        field.tap()
        field.typeText("da")
        app.buttons["Check"].tap()
        sleep(1)
        snapshot("03-practice-incorrect")

        field.typeText(XCUIKeyboardKey.delete.rawValue + XCUIKeyboardKey.delete.rawValue + "de")
        sleep(1)
        snapshot("04-practice-corrected")

        app.buttons["Next"].tap()
        app.buttons["Show hints"].tap()
        sleep(1)
        snapshot("05-practice-hints")
        app.buttons["Close practice"].tap()

        app.swipeUp()
        snapshot("06-home-scrolled")
        app.swipeDown()

        app.buttons["Chapter Practice"].tap()
        sleep(1)
        snapshot("07-chapters")
        app.buttons["HSK 3"].tap()
        sleep(1)
        snapshot("08-chapters-hsk3")
        app.buttons["Cancel"].tap()

        app.buttons["Custom Practice"].tap()
        sleep(1)
        snapshot("09-custom")
        app.buttons["Cancel"].tap()

        app.buttons["Imprint Mode"].tap()
        app.buttons["imprint.selectChapters"].tap()
        sleep(1)
        snapshot("10-imprint-select")
        app.buttons["imprint.chapter1"].tap()
        app.buttons["Done"].tap()
        app.buttons["Start Imprint"].tap()
        sleep(3)
        snapshot("11-imprint-playing")
        app.buttons["Stop"].tap()
        app.buttons["Close"].tap()

        app.buttons["Progress"].tap()
        sleep(1)
        snapshot("12-progress")
        app.swipeUp()
        snapshot("13-progress-scrolled")
        app.buttons["Done"].tap()

        app.buttons["Settings"].tap()
        sleep(1)
        snapshot("14-settings")
        app.swipeUp()
        snapshot("15-settings-scrolled")
        app.swipeUp()
        snapshot("16-settings-bottom")
    }
}
