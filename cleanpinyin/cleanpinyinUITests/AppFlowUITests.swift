import XCTest

final class AppFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    private var character: XCUIElement { app.staticTexts["practice.character"] }
    private var answerField: XCUIElement { app.textFields["Pinyin answer"] }

    private func openQuickPractice() {
        app.buttons["Quick Practice"].tap()
        XCTAssertTrue(answerField.waitForExistence(timeout: 5))
    }

    private func waitUntil(_ element: XCUIElement, _ format: String, timeout: TimeInterval = 5) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: format), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "\(element) never matched \(format)")
    }

    // PRA-2, ANS-1, ANS-7, PROG-1
    func testCorrectAnswerAutoSubmitsAndCountsAsLearned() {
        openQuickPractice()
        XCTAssertEqual(character.label, "的")

        answerField.tap()
        answerField.typeText("de")
        XCTAssertTrue(app.staticTexts["1/150"].waitForExistence(timeout: 5), "the correct answer should submit itself and advance")

        app.buttons["Close practice"].tap()
        waitUntil(app.buttons["home.wordsLearned"], "label BEGINSWITH '1'")
    }

    // ANS-1: multi-syllable words typed without spaces
    func testMultiSyllableAnswerWithoutSpaces() {
        openQuickPractice()
        answerField.tap()

        for _ in 0..<40 where character.label.count == 1 {
            app.buttons["Skip"].tap()
            app.buttons["Next"].tap()
        }
        XCTAssertGreaterThan(character.label.count, 1, "expected to reach a multi-character word")
        let word = character.label

        app.buttons["Skip"].tap()
        let answerBanner = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Correct answer:'")).firstMatch
        XCTAssertTrue(answerBanner.waitForExistence(timeout: 3))
        let pinyin = answerBanner.label.replacingOccurrences(of: "Correct answer: ", with: "")
        let typed = pinyin.folding(options: .diacriticInsensitive, locale: nil).replacingOccurrences(of: " ", with: "")

        answerField.typeText(typed)
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 2))
        XCTAssertEqual(character.label, word, "a corrected answer waits for Next")
    }

    // PRA-3, PRA-4, MODE-4
    func testWrongAnswerShowsCorrectionAndFeedsReview() {
        XCTAssertFalse(app.buttons["Smart Review"].isEnabled)

        openQuickPractice()
        answerField.tap()
        answerField.typeText("xyz")
        app.buttons["Check"].tap()

        XCTAssertTrue(app.staticTexts["Correct answer: de"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["1/150"].waitForExistence(timeout: 5))

        app.buttons["Close practice"].tap()
        let review = app.buttons["Smart Review"]
        XCTAssertTrue(review.waitForExistence(timeout: 3))
        XCTAssertTrue(review.isEnabled)
        XCTAssertTrue(review.label.contains("1 due"))
    }

    // CH-3, MODE-2
    func testChapterPracticeRespectsLocks() {
        app.buttons["Chapter Practice"].tap()
        let first = app.buttons["chapter1"]
        XCTAssertTrue(first.waitForExistence(timeout: 3))
        XCTAssertTrue(first.isEnabled)
        XCTAssertFalse(app.buttons["chapter2"].isEnabled)

        first.tap()
        XCTAssertTrue(app.staticTexts["29 words selected"].exists)
        app.buttons["Start"].tap()

        XCTAssertTrue(app.staticTexts["Chapter Practice"].waitForExistence(timeout: 5))
        XCTAssertTrue(character.exists)
    }

    // SET-2, MODE-5
    func testQuickPracticeLevelsComeFromSettings() {
        XCTAssertTrue(app.buttons["Quick Practice"].label.contains("150 words"))

        app.buttons["Settings"].tap()
        app.buttons["HSK 2"].tap()
        app.buttons["HSK 1"].tap()
        app.buttons["Done"].tap()

        waitUntil(app.buttons["Quick Practice"], "label CONTAINS '147 words'")
    }

    // MODE-3
    func testCustomPracticeDoesNotChangeQuickPractice() {
        app.buttons["Custom Practice"].tap()
        app.buttons["HSK 3"].tap()
        app.buttons["hsk3_set1"].tap()
        app.buttons["Start"].tap()

        XCTAssertTrue(app.staticTexts["Custom Practice"].waitForExistence(timeout: 5))
        app.buttons["Close practice"].tap()
        app.buttons["Cancel"].tap()

        waitUntil(app.buttons["Quick Practice"], "label CONTAINS '150 words'")
    }

    // IMP-1, IMP-3
    func testImprintModePlaysAndStops() {
        app.buttons["Imprint Mode"].tap()
        XCTAssertFalse(app.buttons["Start Imprint"].isEnabled)

        app.buttons["imprint.selectChapters"].tap()
        app.buttons["imprint.chapter1"].tap()
        app.buttons["Done"].tap()

        app.buttons["Start Imprint"].tap()
        XCTAssertTrue(app.staticTexts["1 of 29"].waitForExistence(timeout: 5))

        app.buttons["Stop"].tap()
        XCTAssertTrue(app.buttons["Start Imprint"].waitForExistence(timeout: 3))
        app.buttons["Close"].tap()
    }

    // PROG-5
    func testProgressScreenShowsTotals() {
        app.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["of 4993 HSK words"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["0-day streak"].exists)
        app.buttons["Done"].tap()
    }
}
