// SPDX-License-Identifier: GPL-3.0-or-later

/// Legacy credentials must never overwrite a validated SDK session on a migration retry.
enum MigrationRetryPolicy {
    static func canReuse(expectedSessionID: String, existingSessionID: String,
                         expectedUserID: String, existingUserID: String,
                         isApproved: Bool, isAuthenticated: Bool) -> Bool {
        isApproved && AccountAccessPolicy.canRestore(
            requestedSessionID: expectedSessionID, returnedSessionID: existingSessionID,
            accountUserID: expectedUserID, sessionUserID: existingUserID, isAuthenticated: isAuthenticated
        )
    }
}
