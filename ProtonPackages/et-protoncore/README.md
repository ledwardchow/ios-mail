# Public community adapters

These are new GPL-3.0-or-later compatibility implementations, not Proton's unpublished Apple packages. They use the separately reconstructed, pinned 0.165.4 SDK for authentication, cryptography, persisted sessions and account operations. No authentication token, authenticated session or mail data is fabricated.

Supported account flows implemented here: username/password via the SDK's SRP login flow, TOTP, mailbox password, restored authenticated sessions, account switching and confirmed sign-out. Security validation remains in the SDK. Partial sessions, mismatched account/session IDs and contradictory login states are rejected.

Unsupported operations are visibly unavailable and fail closed: human-verification challenges, security-key authentication, QR login, password recovery and password/security-key settings. StoreKit purchases and transaction observation are disabled. Existing account entitlements remain the real SDK's responsibility. Do not use this experimental client as the sole access method for an account.

UI utilities are ordinary native SwiftUI replacements, not replicas of private Proton visuals. Checked-in tests cover account validation and cancellation, nested observation, and the disabled commerce boundary. Live login and mailbox functionality require separate authorized testing; successful compilation alone proves neither.
