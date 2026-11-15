// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest
@testable import AccountLogin

final class MigrationRetryPolicyTests: XCTestCase {
    func testExactApprovedAuthenticatedSessionCanBeReused() {
        XCTAssertTrue(canReuse())
    }
    func testUnapprovedOrPartialSessionCannotBeReused() {
        XCTAssertFalse(canReuse(approved: false))
        XCTAssertFalse(canReuse(authenticated: false))
        XCTAssertFalse(canReuse(approved: false, authenticated: false))
    }
    func testDifferentSessionOrAccountCannotBeReused() {
        XCTAssertFalse(canReuse(sessionID: "other-session"))
        XCTAssertFalse(canReuse(userID: "other-account"))
    }
    func testMissingIdentityCannotBeReused() {
        XCTAssertFalse(MigrationRetryPolicy.canReuse(expectedSessionID: "", existingSessionID: "", expectedUserID: "account", existingUserID: "account", isApproved: true, isAuthenticated: true))
        XCTAssertFalse(MigrationRetryPolicy.canReuse(expectedSessionID: "session", existingSessionID: "session", expectedUserID: "", existingUserID: "", isApproved: true, isAuthenticated: true))
    }
    private func canReuse(sessionID: String = "session", userID: String = "account", approved: Bool = true, authenticated: Bool = true) -> Bool {
        MigrationRetryPolicy.canReuse(expectedSessionID: "session", existingSessionID: sessionID,
            expectedUserID: "account", existingUserID: userID, isApproved: approved, isAuthenticated: authenticated)
    }
}
