// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@testable import AccountLogin

final class AccountAccessPolicyTests: XCTestCase {
    func testRestoresOnlyAuthenticatedSessionForMatchingAccountAndSessionIDs() {
        XCTAssertTrue(canRestore())
        XCTAssertFalse(canRestore(authenticated: false))
        XCTAssertFalse(canRestore(returnedID: "different-session"))
        XCTAssertFalse(canRestore(sessionUserID: "another-account"))
        XCTAssertFalse(canRestore(requestedID: "", returnedID: ""))
        XCTAssertFalse(canRestore(accountUserID: "", sessionUserID: ""))
    }

    func testFinishedLoginAllowsAccess() {
        XCTAssertEqual(next(loggedIn: true), .authenticated)
    }

    func testPendingSupportedChallengesNeverGrantAccess() {
        XCTAssertEqual(next(totp: true), .totp)
        XCTAssertEqual(next(mailbox: true), .mailboxPassword)
    }

    func testUnsupportedOrIncompleteFlowsFailClosed() {
        XCTAssertEqual(next(), .unsupported)
        XCTAssertEqual(next(newPassword: true), .unsupported)
        XCTAssertEqual(next(host: true), .unsupported)
    }

    func testEveryContradictoryLoginStateFailsClosed() {
        // Exhaust all 32 combinations, rather than testing only one happy path.
        for bits in 0..<32 {
            let loggedIn = bits & 1 != 0
            let totp = bits & 2 != 0
            let mailbox = bits & 4 != 0
            let newPassword = bits & 8 != 0
            let host = bits & 16 != 0
            let pending = [totp, mailbox, newPassword, host].filter { $0 }.count
            if pending > 1 || (loggedIn && pending > 0) {
                XCTAssertEqual(next(loggedIn: loggedIn, totp: totp, mailbox: mailbox, newPassword: newPassword, host: host), .unsupported, "State bits: \(bits)")
            }
        }
    }

    private func canRestore(requestedID: String = "session", returnedID: String = "session", accountUserID: String = "account", sessionUserID: String = "account", authenticated: Bool = true) -> Bool {
        AccountAccessPolicy.canRestore(requestedSessionID: requestedID, returnedSessionID: returnedID, accountUserID: accountUserID, sessionUserID: sessionUserID, isAuthenticated: authenticated)
    }
    private func next(loggedIn: Bool = false, totp: Bool = false, mailbox: Bool = false, newPassword: Bool = false, host: Bool = false) -> AccountAccessPolicy.NextStep {
        AccountAccessPolicy.nextStep(isLoggedIn: loggedIn, awaitingTwoFactor: totp, awaitingMailboxPassword: mailbox, awaitingNewPassword: newPassword, awaitingHostDevice: host)
    }
}
