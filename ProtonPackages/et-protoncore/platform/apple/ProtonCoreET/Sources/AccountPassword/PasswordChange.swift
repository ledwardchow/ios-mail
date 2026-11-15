// SPDX-License-Identifier: GPL-3.0-or-later

import AccountLogin
import SwiftUI
import proton_app_uniffi

public enum PasswordChange {
    public enum Mode {
        case singlePassword(MailUserSession)
        case loginPassword(MailUserSession)
        case mailboxPassword(MailUserSession)
    }
    public struct State: Hashable {
        private let id = UUID()
        public let mode: Mode
        public init(mode: Mode, onTransition: @escaping (State?) -> Void) { self.mode = mode }
        public static func == (lhs: State, rhs: State) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }
    public static func view(from state: State) -> some View {
        UnsupportedAccountOperation(title: "Change password")
    }
}
