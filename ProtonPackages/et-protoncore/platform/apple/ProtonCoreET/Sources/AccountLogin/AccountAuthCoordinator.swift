// SPDX-License-Identifier: GPL-3.0-or-later

import AccountChallenge
import Combine
import Foundation
@_exported import ProtonCoreUtilities
@_exported import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

public struct AccountAdapterError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

@MainActor
public final class AccountAuthCoordinator: ObservableObject {
    @Published public private(set) var primaryAccountSession: StoredSession?
    @Published public private(set) var accounts: [StoredAccount] = []
    @Published public var errorMessage: String?
    public var logFileUrlProvider: (() throws -> URL)?
    public let appContext: MailSession?
    private var handles: [WatchHandle] = []
    private var observationTask: Task<Void, Never>?
    private var challengeObserver: AnyCancellable?
    private var approvedSessionIDs = Set<String>()
    private static let validatedSessionsKey = "ProtonDuo.validatedSessionIDs.v1"

    public init(productName: String, appContext: MailSession) {
        self.appContext = appContext
        if let persisted = UserDefaults.standard.stringArray(forKey: Self.validatedSessionsKey) {
            approvedSessionIDs = Set(persisted)
        } else if case .ok(let existingAccounts) = appContext.getAccountsBlocking() {
            // Adopt only pre-existing authenticated sessions once. Subsequent logins must
            // finish validation before being written to this non-secret session-ID ledger.
            for account in existingAccounts {
                if case .loggedIn(let ids) = account.state() {
                    for id in ids {
                        if case .ok(let session?) = appContext.getSessionBlocking(sessionId: id),
                           case .authenticated = session.state(), session.userId() == account.userId(), session.sessionId() == id {
                            approvedSessionIDs.insert(id)
                        }
                    }
                }
            }
        }
        persistApprovedSessionIDs()
        refresh()
        challengeObserver = NotificationCenter.default.publisher(for: AccountChallengeCoordinator.unsupportedChallenge)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.errorMessage = "Proton requires human verification. This build cannot complete that challenge. Sign-in was cancelled; use the official Proton app or website."
            }
        let callback = SessionUpdates(coordinator: self)
        observationTask = Task { [weak self, appContext] in
            if case .ok(let watched) = await appContext.watchSessionsAsync(callback: callback) {
                self?.handles.append(watched.handle)
            }
            if case .ok(let watched) = await appContext.watchAccountsAsync(callback: callback) {
                self?.handles.append(watched.handle)
            }
            self?.refresh()
        }
    }

    private init() { appContext = nil }
    // Preview-only instance. It cannot create sessions or authenticate.
    public static func mock() -> AccountAuthCoordinator { .init() }

    public func primaryAccountSignedInSession() -> StoredSession? { primaryAccountSession }
    public func refresh() {
        guard let appContext else { return }
        if case .ok(let stored) = appContext.getAccountsBlocking() { accounts = stored }
        var selected: StoredSession?
        if case .ok(let account?) = appContext.getPrimaryAccountBlocking(),
            case .loggedIn(let ids) = account.state()
        {
            for id in ids where approvedSessionIDs.contains(id) {
                if case .ok(let session?) = appContext.getSessionBlocking(sessionId: id),
                    case .authenticated = session.state(),
                    AccountAccessPolicy.canRestore(
                        requestedSessionID: id, returnedSessionID: session.sessionId(),
                        accountUserID: account.userId(), sessionUserID: session.userId(), isAuthenticated: true,
                    )
                {
                    selected = session
                    break
                }
            }
        }
        // A newly stored but unvalidated login must not replace the active account.
        if selected == nil, let previous = primaryAccountSession,
           approvedSessionIDs.contains(previous.sessionId()),
           case .ok(let current?) = appContext.getSessionBlocking(sessionId: previous.sessionId()),
           case .authenticated = current.state(), current.userId() == previous.userId(), current.sessionId() == previous.sessionId() {
            selected = current
        }
        if selected?.sessionId() != primaryAccountSession?.sessionId() { primaryAccountSession = selected }
    }

    func requiresSignInRecovery(_ account: StoredAccount) -> Bool {
        AccountResumePolicy.requiresRecovery(accountState: account.state(), approvedSessionIDs: approvedSessionIDs)
    }

    public func selectAccount(_ account: StoredAccount) async throws {
        guard let appContext, case .loggedIn(let ids) = account.state(),
              ids.contains(where: approvedSessionIDs.contains) else {
            throw AccountAdapterError("This account needs to sign in again.")
        }
        guard case .ok = await appContext.setPrimaryAccount(userId: account.userId()) else {
            throw AccountAdapterError("Could not switch accounts.")
        }
        refresh()
    }

    public func signOut(_ account: StoredAccount) async throws {
        guard let appContext else { throw AccountAdapterError("No account session is available.") }
        guard case .ok = await appContext.logoutAccount(userId: account.userId()) else {
            throw AccountAdapterError("Could not sign out. Please try again.")
        }
        refresh()
    }

    public func migrateLegacySessions(migrationPayloads: [MigrationData]) async throws {
        guard let appContext else { throw AccountAdapterError("No account session is available.") }
        var validated: [StoredSession] = []
        for data in migrationPayloads {
            // Migrating again would replace the SDK's potentially rotated refresh token
            // with the legacy token. Reuse only an exact, previously validated session.
            let existingResult = await appContext.getSession(sessionId: data.sessionId)
            guard case .ok(let existing) = existingResult else {
                throw AccountAdapterError("Could not verify existing sessions. Migration was stopped without replaying legacy credentials.")
            }
            if let existing {
                let authenticated: Bool
                if case .authenticated = existing.state() { authenticated = true } else { authenticated = false }
                guard MigrationRetryPolicy.canReuse(
                    expectedSessionID: data.sessionId, existingSessionID: existing.sessionId(),
                    expectedUserID: data.userId, existingUserID: existing.userId(),
                    isApproved: approvedSessionIDs.contains(existing.sessionId()), isAuthenticated: authenticated
                ) else {
                    throw AccountAdapterError("An existing session conflicts with migration or has not finished verification. Explicit account recovery is required; no session was overwritten or removed.")
                }
                validated.append(existing)
                continue
            }
            guard case .ok(let existingAccount) = await appContext.getAccount(userId: data.userId) else {
                throw AccountAdapterError("Could not verify the account before migration. Legacy credentials were preserved.")
            }
            if let existingAccount {
                guard existingAccount.userId() == data.userId,
                      case .ok(let sessions) = await appContext.getAccountSessions(account: existingAccount), sessions.isEmpty else {
                    throw AccountAdapterError("This account already has another session. Explicit account recovery is required before migration; no session was overwritten or removed.")
                }
            }
            guard case .ok(let flow) = await appContext.newLoginFlow() else {
                throw AccountAdapterError("Could not initialize session migration.")
            }
            guard case .ok = await flow.migrate(data: data), flow.isLoggedIn(),
                  case .ok(let sessionId) = flow.sessionId(), sessionId == data.sessionId,
                  case .ok(let userId) = flow.userId(), userId == data.userId,
                  case .ok(let stored?) = await appContext.getSession(sessionId: sessionId),
                  case .authenticated = stored.state(),
                  AccountAccessPolicy.canRestore(requestedSessionID: sessionId, returnedSessionID: stored.sessionId(),
                      accountUserID: userId, sessionUserID: stored.userId(), isAuthenticated: true) else {
                throw AccountAdapterError("Session migration did not finish. Existing credentials have not been discarded.")
            }
            validated.append(stored)
        }
        validated.forEach(approveValidatedSession)
        refresh()
    }

    func approveValidatedSession(_ session: StoredSession) {
        guard case .authenticated = session.state(), !session.sessionId().isEmpty, !session.userId().isEmpty else { return }
        approvedSessionIDs.insert(session.sessionId())
        persistApprovedSessionIDs()
    }

    private func persistApprovedSessionIDs() {
        UserDefaults.standard.set(Array(approvedSessionIDs), forKey: Self.validatedSessionsKey)
    }

    public func accountView() -> some View { AccountSignInView(coordinator: self) }
    public func securityKeyListView(userSettings: UserSettings) -> some View {
        UnsupportedAccountOperation(title: "Security keys")
    }
}

private final class SessionUpdates: AsyncLiveQueryCallback, @unchecked Sendable {
    private weak var coordinator: AccountAuthCoordinator?
    @MainActor init(coordinator: AccountAuthCoordinator) { self.coordinator = coordinator }
    func onUpdate() async { await coordinator?.refresh() }
}

public struct UnsupportedAccountOperation: View {
    private let title: String
    public init(title: String) { self.title = title }
    public var body: some View {
        ContentUnavailableView(
            title, systemImage: "lock.shield", description: Text("This operation is not available in this community build. Manage your account using the official Proton app or account.proton.me."),)
    }
}
