// SPDX-License-Identifier: GPL-3.0-or-later

@_exported import AccountLogin
import Combine
import SwiftUI
import proton_app_uniffi

@MainActor
public final class AccountManagerCoordinator: ObservableObject {
    public let accountAuthCoordinator: AccountAuthCoordinator
    private var subscription: AnyCancellable?
    public init(appContext: MailSession, accountAuthCoordinator: AccountAuthCoordinator) {
        self.accountAuthCoordinator = accountAuthCoordinator
        subscription = accountAuthCoordinator.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }
    }
    public func avatarView() -> some View {
        Image(systemName: "person.crop.circle.fill").font(.title2).accessibilityLabel("Switch account")
    }
}

private struct AccountSwitcher: View {
    @ObservedObject var coordinator: AccountAuthCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showSignIn = false
    @State private var signOutCandidate: StoredAccount?
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        NavigationStack {
            List {
                ForEach(coordinator.accounts, id: \.userIdValue) { account in
                    Button {
                        Task {
                            busy = true
                            defer { busy = false }
                            do {
                                try await coordinator.selectAccount(account)
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(account.details().name)
                            Text(account.details().email).font(.caption)
                            if case .loggedIn = account.state() {} else { Text("Sign-in required").font(.caption) }
                        }
                    }
                    .swipeActions {
                        Button("Sign out", role: .destructive) { signOutCandidate = account }
                    }
                }
                Button("Add account") { showSignIn = true }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .disabled(busy)
            .navigationTitle("Accounts")
            .toolbar { Button("Done") { dismiss() } }
            .sheet(isPresented: $showSignIn) { coordinator.accountView() }
            .alert("Sign out of this account?", isPresented: Binding(get: { signOutCandidate != nil }, set: { if !$0 { signOutCandidate = nil } })) {
                Button("Cancel", role: .cancel) { signOutCandidate = nil }
                Button("Sign out", role: .destructive) {
                    guard let account = signOutCandidate else { return }
                    Task {
                        busy = true
                        defer {
                            busy = false
                            signOutCandidate = nil
                        }
                        do { try await coordinator.signOut(account) } catch { self.error = error.localizedDescription }
                    }
                }
            }
        }
    }
}

private extension StoredAccount { var userIdValue: String { userId() } }

public extension View {
    @MainActor func withAccountManagerSwitcher(isPresented: Binding<Bool>, coordinator: AccountManagerCoordinator) -> some View {
        sheet(isPresented: isPresented) { AccountSwitcher(coordinator: coordinator.accountAuthCoordinator) }
    }
    @MainActor func withDuplicateAccountAlert(isPresented: Binding<Bool>, coordinator: AccountAuthCoordinator) -> some View {
        alert("Account already signed in", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Select the existing account in the account switcher.")
        }
    }
}
