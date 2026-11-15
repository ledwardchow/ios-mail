// SPDX-License-Identifier: GPL-3.0-or-later

/// Pure decisions shared by restoration and interactive login. No networking or credentials.
enum AccountAccessPolicy {
    enum NextStep: Equatable {
        case authenticated, totp, mailboxPassword, unsupported
    }

    static func canRestore(
        requestedSessionID: String,
        returnedSessionID: String,
        accountUserID: String,
        sessionUserID: String,
        isAuthenticated: Bool,
    ) -> Bool {
        isAuthenticated && !requestedSessionID.isEmpty && !accountUserID.isEmpty
            && requestedSessionID == returnedSessionID && accountUserID == sessionUserID
    }

    static func nextStep(
        isLoggedIn: Bool,
        awaitingTwoFactor: Bool,
        awaitingMailboxPassword: Bool,
        awaitingNewPassword: Bool,
        awaitingHostDevice: Bool,
    ) -> NextStep {
        let pending = [awaitingTwoFactor, awaitingMailboxPassword, awaitingNewPassword, awaitingHostDevice]
            .filter { $0 }.count
        // Inconsistent SDK state never grants access or chooses an arbitrary challenge.
        guard pending <= 1, !(isLoggedIn && pending > 0) else { return .unsupported }
        if isLoggedIn { return .authenticated }
        if awaitingTwoFactor { return .totp }
        if awaitingMailboxPassword { return .mailboxPassword }
        return .unsupported
    }
}
