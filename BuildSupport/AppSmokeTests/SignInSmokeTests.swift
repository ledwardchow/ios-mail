// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

final class SignInSmokeTests: XCTestCase {
    @MainActor
    func testFreshSignInFormAndRelaunchWithoutSubmittingCredentials() {
        let app = XCUIApplication()
        app.launch()
        let username = app.textFields["Proton username or email"]
        XCTAssertTrue(username.waitForExistence(timeout: 20))
        let password = app.secureTextFields["Password"]
        XCTAssertTrue(password.exists)
        let next = app.buttons["Continue"]
        XCTAssertFalse(next.isEnabled)
        username.tap()
        username.typeText("local-ui-check")
        XCTAssertFalse(next.isEnabled)
        password.tap()
        password.typeText("not-a-real-password")
        XCTAssertTrue(next.isEnabled)
        // Never tap Continue: this test does not attempt account authentication.
        app.terminate()
        app.launch()
        XCTAssertTrue(username.waitForExistence(timeout: 20))
        XCTAssertEqual(username.value as? String, "Proton username or email")
        XCTAssertFalse(next.isEnabled)
    }
}
