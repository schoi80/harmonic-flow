import XCTest

final class HarmonicFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesAndShowsTitle() throws {
        let app = XCUIApplication()
        app.launch()

        let titleText = app.staticTexts["HarmonicFlow"]
        XCTAssertTrue(titleText.exists, "The main title should be visible on launch.")
    }
}
