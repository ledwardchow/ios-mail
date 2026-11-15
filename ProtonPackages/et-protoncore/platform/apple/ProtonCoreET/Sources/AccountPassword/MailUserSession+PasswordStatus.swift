// SPDX-License-Identifier: GPL-3.0-or-later
import proton_app_uniffi

public extension MailUserSession {
    /// Unknown or unavailable settings remain unknown; they must not imply single-password mode.
    func hasMailboxPassword() async -> Bool? {
        guard case .ok(let settings) = await userSettings() else { return nil }
        return MailboxPasswordStatus.decode(mode: settings.password.mode)
    }
}
