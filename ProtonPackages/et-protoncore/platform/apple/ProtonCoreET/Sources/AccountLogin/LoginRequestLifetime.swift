// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// A completion may affect the screen only while it still owns its request token.
struct LoginRequestLifetime {
    private var current: UUID?

    mutating func begin() -> UUID {
        let token = UUID()
        current = token
        return token
    }

    mutating func invalidate() { current = nil }

    func permits(_ token: UUID, isCancelled: Bool) -> Bool {
        !isCancelled && current == token
    }
}
