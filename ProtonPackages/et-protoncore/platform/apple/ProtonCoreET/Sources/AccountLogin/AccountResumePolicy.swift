// SPDX-License-Identifier: GPL-3.0-or-later
import proton_app_uniffi

enum AccountResumePolicy {
    static func partialSessionIDs(_ state: StoredAccountState) -> [String] {
        switch state {
        case .needTfa(let ids), .needMbp(let ids): return ids
        default: return []
        }
    }

    static func permits(accountState: StoredAccountState, sessionState: StoredSessionState,
                        requestedID: String, returnedID: String, accountUserID: String, sessionUserID: String) -> Bool {
        guard !requestedID.isEmpty, !accountUserID.isEmpty, requestedID == returnedID,
              accountUserID == sessionUserID, partialSessionIDs(accountState).contains(requestedID) else { return false }
        switch (accountState, sessionState) {
        case (.needTfa, .needTfa), (.needMbp, .needKey): return true
        default: return false
        }
    }

    static func requiresRecovery(accountState: StoredAccountState, approvedSessionIDs: Set<String>) -> Bool {
        guard case .loggedIn(let ids) = accountState else { return false }
        return !ids.isEmpty && !ids.contains(where: approvedSessionIDs.contains)
    }

    static func supportsTotp(_ result: LoginFlowTfaMethodsResult) -> Bool {
        switch result {
        case .ok(.totp), .ok(.totpAndFido2): return true
        default: return false
        }
    }
}
