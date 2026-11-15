// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import proton_app_uniffi

@MainActor
struct AccountSignInView: View {
    @ObservedObject var coordinator: AccountAuthCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var code = ""
    @State private var flow: LoginFlow?
    @State private var stage = Stage.credentials
    @State private var busy = false
    @State private var message: String?
    @State private var submitTask: Task<Void, Never>?
    @State private var requestLifetime = LoginRequestLifetime()
    @State private var recoveryAccount: StoredAccount?
    private enum Stage { case credentials, totp, mailboxPassword, unsupported }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Proton Mail Duo").font(.title.bold())
                    Text("Community build using Proton's public SDK. Enter credentials only here on your own device. Passwords and verification codes are passed directly to the SDK; this sign-in interface does not log them.")
                        .font(.footnote)
                }
                if stage == .credentials && coordinator.accounts.contains(where: { !AccountResumePolicy.partialSessionIDs($0.state()).isEmpty || coordinator.requiresSignInRecovery($0) }) {
                    Section("Continue an unfinished sign-in") {
                        ForEach(coordinator.accounts.filter { !AccountResumePolicy.partialSessionIDs($0.state()).isEmpty }, id: \.resumeUserID) { account in
                            Button(account.details().email) { beginResume(account) }
                        }
                        ForEach(coordinator.accounts.filter(coordinator.requiresSignInRecovery), id: \.resumeUserID) { account in
                            Button("Restart interrupted sign-in: \(account.details().email)") { recoveryAccount = account }
                        }
                    }
                }
                Section("Sign in") {
                    switch stage {
                    case .credentials:
                        TextField("Proton username or email", text: $username)
                            .textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
                        SecureField("Password", text: $password).textContentType(.password)
                    case .totp:
                        Text("Enter your authenticator code. Security-key authentication is not supported by this build.")
                        SecureField("Authenticator code", text: $code).textContentType(.oneTimeCode).keyboardType(.numberPad)
                    case .mailboxPassword:
                        SecureField("Mailbox password", text: $password).textContentType(.password)
                    case .unsupported:
                        Text("This account requires a sign-in step this build cannot complete. Use the official Proton app or website.")
                    }
                    if stage != .unsupported {
                        Button("Continue", action: beginSubmit)
                            .disabled(busy || (stage == .credentials && (username.isEmpty || password.isEmpty)) || (stage == .totp && code.isEmpty) || (stage == .mailboxPassword && password.isEmpty))
                    }
                    if busy { ProgressView("Signing in…") }
                    if stage != .credentials {
                        Button("Start over") {
                            flow = nil
                            stage = .credentials
                            password = ""
                            code = ""
                            message = nil
                            coordinator.refresh()
                        }
                        .disabled(busy)
                    }
                }
                if let error = coordinator.errorMessage ?? message {
                    Section { Text(error).foregroundStyle(.red) }
                }
                Section {
                    Text("Account creation, password recovery, security keys and human-verification challenges are not supported here. No verification or encryption checks are bypassed.")
                        .font(.footnote)
                }
            }
            .disabled(busy)
            .navigationTitle("Sign in")
        }
        .interactiveDismissDisabled(busy)
        .alert("Restart interrupted sign-in?", isPresented: Binding(get: { recoveryAccount != nil }, set: { if !$0 { recoveryAccount = nil } }), presenting: recoveryAccount) { account in
            Button("Cancel", role: .cancel) { recoveryAccount = nil }
            Button("Sign out and retry", role: .destructive) { beginRecovery(account) }
        } message: { account in
            Text("Sign out of the interrupted session for \(account.details().email) and remove its local session data so you can sign in again? Other accounts are not changed.")
        }
        .onDisappear {
            requestLifetime.invalidate()
            submitTask?.cancel()
            submitTask = nil
            busy = false
            password = ""
            code = ""
            flow = nil
            stage = .credentials
        }
    }

    private func beginSubmit() {
        guard !busy else { return }
        let token = requestLifetime.begin()
        busy = true
        submitTask = Task { await submit(token: token) }
    }

    private func isCurrent(_ token: UUID) -> Bool {
        requestLifetime.permits(token, isCancelled: Task.isCancelled)
    }

    private func submit(token: UUID) async {
        guard isCurrent(token) else { return }
        defer {
            if isCurrent(token) {
                busy = false
                password = ""
                code = ""
                submitTask = nil
            }
        }
        guard let app = coordinator.appContext else {
            message = "Sign-in is not available in previews."
            return
        }
        message = nil
        coordinator.errorMessage = nil
        if flow == nil {
            let result = await app.newLoginFlow()
            guard isCurrent(token) else { return }
            guard case .ok(let newFlow) = result else {
                message = "Could not start sign-in. Please try again."
                return
            }
            flow = newFlow
        }
        guard let flow else { return }
        var failure: LoginError?
        switch stage {
        case .credentials:
            if case .error(let error) = await flow.login(username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password, userBehavior: nil) { failure = error }
        case .totp:
            if case .error(let error) = await flow.submitTotp(code: code.trimmingCharacters(in: .whitespacesAndNewlines)) { failure = error }
        case .mailboxPassword:
            if case .error(let error) = await flow.submitMailboxPassword(mailboxPassword: password) { failure = error }
        case .unsupported: return
        }
        // SDK calls may finish despite Swift task cancellation. Ignore their late completion.
        guard isCurrent(token) else { return }
        if let failure {
            switch failure {
            case .invalidCredentials: message = "Incorrect username or password."
            case .incorrect2FaCode: message = "Incorrect authenticator code."
            case .cantUnlockUserKey: message = "The mailbox password could not unlock your encryption keys."
            case .duplicateSession(let sessionID):
                await resume(sessionID: sessionID, expectedUserID: nil, token: token)
                return
            default: message = "Proton could not complete sign-in. Check your connection or use the official Proton app if additional verification is required."
            }
            return
        }
        await advance(flow: flow, token: token)
    }

    private func beginRecovery(_ account: StoredAccount) {
        guard !busy, coordinator.requiresSignInRecovery(account), let app = coordinator.appContext else { return }
        let token = requestLifetime.begin()
        busy = true
        recoveryAccount = nil
        submitTask = Task {
            let result = await app.logoutAccount(userId: account.userId())
            guard isCurrent(token) else { return }
            busy = false
            submitTask = nil
            guard case .ok = result else {
                message = "Could not sign out of the interrupted session. Please try again."
                return
            }
            flow = nil
            stage = .credentials
            password = ""
            code = ""
            message = "The interrupted session has been signed out. You can sign in again."
            coordinator.refresh()
        }
    }

    private func beginResume(_ account: StoredAccount) {
        guard !busy, let sessionID = AccountResumePolicy.partialSessionIDs(account.state()).first else { return }
        let token = requestLifetime.begin()
        busy = true
        message = nil
        submitTask = Task {
            await resume(sessionID: sessionID, expectedUserID: account.userId(), token: token)
            if isCurrent(token) { busy = false; submitTask = nil }
        }
    }

    private func resume(sessionID: String, expectedUserID: String?, token: UUID) async {
        guard isCurrent(token), let app = coordinator.appContext else { return }
        let sessionResult = await app.getSession(sessionId: sessionID)
        guard isCurrent(token) else { return }
        guard case .ok(let session?) = sessionResult,
              expectedUserID == nil || session.userId() == expectedUserID else {
            message = "The unfinished sign-in is unavailable."
            return
        }
        let accountResult = await app.getAccount(userId: session.userId())
        guard isCurrent(token) else { return }
        guard case .ok(let account?) = accountResult,
              AccountResumePolicy.permits(accountState: account.state(), sessionState: session.state(),
                requestedID: sessionID, returnedID: session.sessionId(), accountUserID: account.userId(), sessionUserID: session.userId()) else {
            message = "This account cannot resume a supported sign-in step. If it is already signed in, select it from Accounts. Otherwise use the official Proton app."
            return
        }
        let resumed = await app.resumeLoginFlow(userId: account.userId(), sessionId: sessionID)
        guard isCurrent(token) else { return }
        guard case .ok(let restoredFlow) = resumed,
              case .ok(let restoredSessionID) = restoredFlow.sessionId(), restoredSessionID == sessionID,
              case .ok(let restoredUserID) = restoredFlow.userId(), restoredUserID == account.userId() else {
            message = "Proton could not resume this sign-in. No session was removed."
            return
        }
        flow = restoredFlow
        await advance(flow: restoredFlow, token: token)
    }

    private func advance(flow: LoginFlow, token: UUID) async {
        guard isCurrent(token), let app = coordinator.appContext else { return }
        let nextStep = AccountAccessPolicy.nextStep(
            isLoggedIn: flow.isLoggedIn(), awaitingTwoFactor: flow.isAwaiting2fa(),
            awaitingMailboxPassword: flow.isAwaitingMailboxPassword(),
            awaitingNewPassword: flow.isAwaitingNewPassword(),
            awaitingHostDevice: flow.isAwaitingHostDeviceConfirmation(),
        )
        switch nextStep {
        case .authenticated:
            guard case .ok(let sessionId) = flow.sessionId() else {
                message = "Sign-in did not produce a usable authenticated session."
                return
            }
            let storedSession = await app.getSession(sessionId: sessionId)
            guard isCurrent(token) else { return }
            guard case .ok(let session?) = storedSession,
                case .authenticated = session.state(),
                case .ok(let userId) = flow.userId(),
                AccountAccessPolicy.canRestore(
                    requestedSessionID: sessionId, returnedSessionID: session.sessionId(),
                    accountUserID: userId, sessionUserID: session.userId(), isAuthenticated: true,
                )
            else {
                message = "Sign-in did not produce a usable authenticated session."
                return
            }
            // No suspension between the lifetime check and starting account selection.
            guard isCurrent(token) else { return }
            let selection = await app.setPrimaryAccount(userId: session.userId())
            guard isCurrent(token) else { return }
            guard case .ok = selection else {
                message = "Could not select the signed-in account."
                return
            }
            coordinator.approveValidatedSession(session)
            coordinator.refresh()
            dismiss()
        case .totp:
            let methods = await flow.tfaMethods()
            guard isCurrent(token) else { return }
            if AccountResumePolicy.supportsTotp(methods) {
                stage = .totp
            } else {
                stage = .unsupported
                message = "This account requires a security key or an unavailable verification method. Use the official Proton app or website."
            }
        case .mailboxPassword: stage = .mailboxPassword
        case .unsupported: stage = .unsupported
        }
    }
}

public struct ScanQRCodeInstructionsView: View {
    public struct ViewModel {
        public struct Dependencies {
            public init(mailUserSession: MailUserSession, productName: String) {}
        }
        public init(dependencies: Dependencies) {}
    }
    public init(viewModel: ViewModel) {}
    public var body: some View { UnsupportedAccountOperation(title: "QR sign-in") }
}

private extension StoredAccount { var resumeUserID: String { userId() } }
