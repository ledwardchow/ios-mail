// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

final class AdaptiveMailboxUITests: XCTestCase {
    @MainActor func testSelectionDraftAndFolderFlow() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let message = app.buttons["message.welcome"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        message.tap()
        XCTAssertTrue(app.scrollViews["detail.welcome"].waitForExistence(timeout: 5))
        app.buttons["detailCompose"].tap()
        let editor = app.textViews["draftBody"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap(); editor.typeText("Resize-safe unsent draft")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "Resize-safe unsent draft")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "Resize-safe unsent draft")
        app.buttons["closeDraft"].tap()
        XCTAssertTrue(app.scrollViews["detail.welcome"].waitForExistence(timeout: 5))
        app.buttons["detailCompose"].tap()
        XCTAssertEqual(editor.value as? String, "Resize-safe unsent draft")
        app.buttons["closeDraft"].tap()
        if app.buttons["backToInbox"].exists { app.buttons["backToInbox"].tap() }
        app.buttons["folders"].tap()
        app.buttons["folder.Archive"].firstMatch.tap()
        XCTAssertTrue(app.buttons["message.archive"].waitForExistence(timeout: 5))
        app.buttons["message.archive"].tap()
        XCTAssertTrue(app.scrollViews["detail.archive"].waitForExistence(timeout: 5))
    }

    @MainActor func testWideMailboxKeepsListBesideSelection() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        guard app.windows.firstMatch.frame.width >= 640 else { throw XCTSkip("Wide-window test runs on iPad; compact flow is covered separately.") }
        app.buttons["message.welcome"].tap()
        XCTAssertTrue(app.scrollViews["detail.welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["message.weekend"].isHittable)
        app.buttons["message.weekend"].tap()
        XCTAssertTrue(app.scrollViews["detail.weekend"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.scrollViews["detail.weekend"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["message.welcome"].isHittable)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.scrollViews["detail.weekend"].waitForExistence(timeout: 5))
    }
}
