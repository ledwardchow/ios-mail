# Production build investigation

Updated 15 November 2026. **No working production client has been built.** The independent UI experiment is not evidence of mail functionality and is not the next priority.

## Current client: exact evidence

App revision: `701463fe4542945c49ac5d326b0c27e91441e02f`; SDK pin: `0.165.4`.

Re-ran `xcodegen generate` on the unmodified production spec. It exits with invalid local packages `proton_app_uniffi`, `PaymentsUI`, `ProtonCoreET`, and `PaymentsNG`. This is before compilation or a runnable login screen.

Restored the missing `scripts/templates/IDETemplateMacros.plist` from the same upstream repository's v4 source (`ProtonMail/xcodeGen/IDETemplateMacros.plist`, commit `ad74cd98465cea14df2a16e541a6b01a24a877da`). This fixes the later post-generation copy input without changing license notices or account behavior; `plutil -lint` passes. It does not resolve the missing packages.

The exact SDK **does** have a public tag: [ProtonMail/clients mail-uniffi-v0.165.4](https://github.com/ProtonMail/clients/tree/mail-uniffi-v0.165.4), commit `6ef4ff39677fd5cbbc7fcd986b6b0d1b773073f7`. The earlier latest-version comparison was incomplete and is corrected here.

That tag's complete public tree contains no Apple `Package.swift` files supplying the required packages. Its Cargo lockfile also depends on crates from Proton's registry, so the public tag alone is not a ready-made Swift SDK artifact. Registry dependencies and independently published source must be reconciled before a source build can be claimed. This is not proof that all registry dependencies are unavailable: [proton-crypto-rs commit abcca7aa806891beea4bb348a3e1781d7fb01d6c](https://github.com/ProtonMail/proton-crypto-rs/tree/abcca7aa806891beea4bb348a3e1781d7fb01d6c) provides the matching crypto versions. The mail-only SDK source reconstruction has now succeeded. Both Rust targets (arm64 iOS device and simulator), UniFFI Swift generation, and XCFramework packaging passed. All four generated Swift bindings type-check against both slices without diagnostics. The [reproducible recipe and resolved lockfile](BuildSupport/PublicSDK/README-build.md) are included in this fork. This is a default-feature debug SDK, not a byte-identical release, and does not test account login or mail networking.

After installing the generated `proton_app_uniffi` package locally and rerunning XcodeGen, the errors dropped from four to three: `PaymentsNG`, `PaymentsUI`, and `ProtonCoreET`. The Rust SDK package is now supplied; the production app still cannot generate/build until those separate Apple packages are resolved.

## Apple account modules are not just optional UI

The app's `project.yml` requires `AccountChallenge`, `AccountLogin`, `AccountManager`, and `AccountPassword` products from `ProtonCoreET`. `Modules/App/Sources/State/AppContext.swift` creates `AccountChallengeCoordinator` and `AccountAuthCoordinator` during startup, passing them into mail-session creation and restoring the active account through them.

Checked [ProtonMail/protoncore_ios develop](https://github.com/ProtonMail/protoncore_ios/tree/bb1279db594cb5aeeffcddadad23b8dd8a02104a), including its complete recursive tree and Package.swift. It exports older `ProtonCoreLogin`, `ProtonCoreLoginUI`, `ProtonCoreAccountSwitcher`, and related products, not the required `ProtonCoreET` contract. No matching `PaymentsNG` or new account-module implementation was located there. Merely renaming packages or deleting imports would not implement the missing authentication/session behavior.

The share-extension package additionally requests `ProtonUIFoundations` 1.4.2 from Proton's private GitLab (`Modules/TestableShareExtension/Package.swift`). That URL was not contacted.

## Older actual-client fallback investigated

Created a separate local worktree at upstream `v4` commit `ad74cd98465cea14df2a16e541a6b01a24a877da` (4.22.1, July 2025), without changing the production branch or switching the fork default.

The documented setup is not entirely public either:

- `ProtonMail/xcodeGen/specs/base_config.json` depends on `ProtonInboxRSVP` 2.7.0 from Proton's private GitLab.
- RSVP types are imported by calendar services, dependency injection, generated app dependencies, attachment handling, and multiple invitation components. Removing the package entry alone does not make this client build.
- The post-generation script invokes submodule updates and CocoaPods. The test-data submodule and some Podfile URLs reference private infrastructure, though several pod sources are vendored. Those URLs were not contacted.
- [Upstream issue 92](https://github.com/ProtonMail/ios-mail/issues/92) separately records missing RSVP/ICal packages. There is no maintainer-provided public build solution in its comments as checked.

No older client was connected to an account, and no claim is made that this older branch remains supported or safe for production use.

## What unblocks genuine app testing

Provide the matching, legitimately accessible `et-protoncore` Apple source/packages plus a buildable exact-version SDK distribution (or all required public source and build inputs), or an upstream public branch that includes them. Then generate the project, resolve remaining compiler/toolchain issues, build for the simulator, and test login and real mail only under appropriate account authorization.

Reimplementing the missing account/security SDK would be a separate substantial engineering effort, not a dependency-path fix. No mocked login, weakened certificate validation, substituted cryptography, private credentials, or production account changes have been used to create a misleading build success.
