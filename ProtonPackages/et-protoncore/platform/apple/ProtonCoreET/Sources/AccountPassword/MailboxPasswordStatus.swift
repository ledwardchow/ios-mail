// SPDX-License-Identifier: GPL-3.0-or-later
enum MailboxPasswordStatus {
    static func decode(mode: UInt32) -> Bool? {
        // Proton SDK: muon/src/rest/auth/v4/mod.rs, PasswordMode::{One = 1, Two = 2}.
        switch mode {
        case 1: return false
        case 2: return true
        default: return nil
        }
    }
}
