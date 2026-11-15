# Public-source Proton Mail build

Updated 15 November 2026. **The real app now builds and launches on an isolated iPhone Duo simulator. Authenticated mailbox access has not been tested. This is an experimental community build, not a production-ready Proton client.**

## Verified outcome

- XcodeGen generation and public Swift package resolution pass.
- The actual ProtonMail app, ShareExtension and NotificationService build using Xcode 27.2 on Apple Silicon.
- A dedicated clean Duo simulator launches the app and displays the real SDK-backed sign-in form.
- An XCTest UI smoke test passes: empty-form validation, username and secure-password entry, Continue enabling only when complete, and relaunch clearing the fields. The test never submits credentials.
- The actual Rust SDK initializes its encrypted local database and Keychain storage and successfully fetches 227 feature flags from Proton's production API. An earlier TCP timeout was transient. This verifies SDK transport, **not authenticated mail access**.
- The independent sample-data adaptive UI experiment is not used by this app and is not evidence of mailbox functionality. Adaptive mailbox integration remains future work after real-account validation.

## Source reconstruction

The app baseline is upstream `701463fe4542945c49ac5d326b0c27e91441e02f`, pinning SDK `0.165.4`.

The exact public SDK tag is [ProtonMail/clients mail-uniffi-v0.165.4](https://github.com/ProtonMail/clients/tree/mail-uniffi-v0.165.4), commit `6ef4ff39677fd5cbbc7fcd986b6b0d1b773073f7`. Matching public crypto sources are pinned at [proton-crypto-rs abcca7aa806891beea4bb348a3e1781d7fb01d6c](https://github.com/ProtonMail/proton-crypto-rs/tree/abcca7aa806891beea4bb348a3e1781d7fb01d6c). See [the recipe and resolved Cargo lockfile](BuildSupport/PublicSDK/README-build.md).

Both arm64 device and simulator Rust builds, UniFFI generation, XCFramework packaging and Swift binding typechecks pass. This is a source-built default-feature debug SDK, not a byte-identical official release. No SDK authentication/cryptography implementation was replaced by a mock. Binary artifacts are not committed.

The required Apple packages were not published in the checked public source. New GPL-3.0-or-later [community adapters](ProtonPackages/et-protoncore/README.md) implement account/session integration using real SDK calls and ordinary native UI utilities. They are not Proton's unpublished implementations. The share extension now consumes the local public UI product instead of private GitLab. No private repository credentials were used.

Additional integration fixes include public Introspect 27.1.0, public Sentry 9.34.0 (the old binary interface fails with Swift 6.4), faithful typed-error conformances, existing bundled design-system assets, and explicit UI actor isolation. Original licensing notices remain intact.

## Build and test

1. Build and link the SDK following `BuildSupport/PublicSDK/README-build.md`.
2. Run `BuildSupport/PublicSDK/build-app.sh`.
3. Install only on an isolated simulator for now. Do not replace the official app or its data on a real device.

The helper uses normal Xcode ad-hoc simulator signing with no developer-account credentials. This matters: unsigned builds compile but cannot obtain the app-group container and crash on startup. Do not manually sign full device entitlements onto a simulator executable; let Xcode generate simulated entitlements.

`PUBLIC_SOURCE_BUILD=YES` preserves checked-in generated Swift and license files while skipping upstream formatting, Sourcery regeneration and LicensePlist regeneration. It does not skip app compilation, substitute authentication or weaken certificate validation. Standard upstream builds keep their existing tool steps.

The `PublicAppSmokeTests` scheme exercises the actual app without submitting credentials. `PublicAppRegressionTests` runs the migration/settings subset in a dedicated target without unrelated private package snapshot fixtures. Those 20 tests pass using synthetic data in random Keychain services in the simulator’s already-entitled app group; production legacy-access defaults are unchanged. `AllUnitAndSnapshotTests` currently cannot compile because the unpublished `ToastViewPreviewProvider` fixture is missing; no full-suite success is claimed.

The final ProtonCoreET package suite passes 33 tests; the separate payment boundary passes 2 tests, and the actual-app smoke test passes 1 test. Focused package tests cover authenticated identity checks, contradictory states, challenge cancellation, task lifecycle, partial-session resume eligibility, interrupted-login recovery, migration replay prevention, password-mode decoding, nested observation, toast presentation/safe-area ownership, and explicit commerce unavailability. These are not substitutes for end-to-end mailbox tests.

## Security and unsupported features

Implemented SDK-backed paths include SRP username/password login, TOTP, mailbox password, authenticated session restoration, account selection and confirmed sign-out. These paths still require live-account validation. Interrupted requests cannot silently publish a new session; partial sessions can resume through SDK APIs, and an interrupted authenticated session has an explicit account-specific recovery confirmation.

Unsupported operations are visibly unavailable and fail closed: human-verification challenges, FIDO-only security-key sign-in, QR sign-in, account creation/recovery, password/security-key settings and in-app purchasing. Existing account entitlements remain the real SDK's responsibility. No purchase, authentication success or mail data is fabricated.

Legacy migration now preserves credentials on failure, saves settings/protection before publishing migrated sessions, and rejects replay of stale legacy tokens over an existing unvalidated/conflicting SDK session. Exact previously validated authenticated sessions can be reused on retry. Live migration remains untested, and failure retry currently requires a later service invocation/relaunch. Do not rely on this build to migrate the only copy of an account.

## Next gate

A user must sign in directly in the isolated app, never send a password in chat. Then test actual mailbox loading/decryption, session restoration, message reading, draft continuity, and authorized sending. A server human-verification requirement will stop this build rather than bypass the challenge. Only after that should adaptive mailbox layout work be treated as functional client development.
