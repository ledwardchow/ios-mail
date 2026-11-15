// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest
import proton_app_uniffi
@testable import AccountLogin

final class LoginLifecycleAndResumeTests: XCTestCase {
    func testDismissedRequestCannotPublishLateCompletion() {
        var lifetime = LoginRequestLifetime()
        let token = lifetime.begin()
        XCTAssertTrue(lifetime.permits(token, isCancelled: false))
        lifetime.invalidate()
        XCTAssertFalse(lifetime.permits(token, isCancelled: false))
    }

    func testOldCompletionCannotAffectReopenedScreen() {
        var lifetime = LoginRequestLifetime()
        let old = lifetime.begin()
        lifetime.invalidate()
        let current = lifetime.begin()
        XCTAssertFalse(lifetime.permits(old, isCancelled: false))
        XCTAssertTrue(lifetime.permits(current, isCancelled: false))
    }

    func testCancellationRejectsOtherwiseCurrentRequest() {
        var lifetime = LoginRequestLifetime()
        let token = lifetime.begin()
        XCTAssertFalse(lifetime.permits(token, isCancelled: true))
    }

    func testMatchingPartialSessionsCanResume() {
        XCTAssertTrue(permits(account: .needTfa(["session"]), session: .needTfa))
        XCTAssertTrue(permits(account: .needMbp(["session"]), session: .needKey))
    }

    func testMismatchedOrCompleteSessionsCannotResume() {
        XCTAssertFalse(permits(account: .needTfa(["session"]), session: .needKey))
        XCTAssertFalse(permits(account: .needMbp(["session"]), session: .authenticated))
        XCTAssertFalse(permits(account: .loggedIn(["session"]), session: .authenticated))
        XCTAssertFalse(permits(account: .needNewPass(["session"]), session: .needKey))
        XCTAssertFalse(permits(account: .needTfa(["other"]), session: .needTfa))
        XCTAssertFalse(permits(account: .needTfa(["session"]), session: .needTfa, owner: "other-account"))
        XCTAssertFalse(permits(account: .needTfa(["session"]), session: .needTfa, returnedID: "other-session"))
    }

    func testFidoOnlyOrUnknownMethodsNeverRouteToTotp() {
        XCTAssertTrue(AccountResumePolicy.supportsTotp(.ok(.totp)))
        XCTAssertTrue(AccountResumePolicy.supportsTotp(.ok(.totpAndFido2)))
        XCTAssertFalse(AccountResumePolicy.supportsTotp(.ok(.fido2)))
        XCTAssertFalse(AccountResumePolicy.supportsTotp(.error(.invalidState)))
    }

    func testUnvalidatedAuthenticatedSessionOffersExplicitRecoveryInsteadOfAccess() {
        XCTAssertTrue(AccountResumePolicy.requiresRecovery(accountState: .loggedIn(["new"]), approvedSessionIDs: ["old"]))
        XCTAssertFalse(AccountResumePolicy.requiresRecovery(accountState: .loggedIn(["old"]), approvedSessionIDs: ["old"]))
        XCTAssertFalse(AccountResumePolicy.requiresRecovery(accountState: .needTfa(["new"]), approvedSessionIDs: []))
        XCTAssertFalse(AccountResumePolicy.requiresRecovery(accountState: .loggedOut, approvedSessionIDs: []))
    }

    private func permits(account: StoredAccountState, session: StoredSessionState, owner: String = "account", returnedID: String = "session") -> Bool {
        AccountResumePolicy.permits(accountState: account, sessionState: session, requestedID: "session", returnedID: returnedID,
            accountUserID: "account", sessionUserID: owner)
    }
}
