# Public Proton Mail SDK 0.165.4 reconstruction

Status: **SDK build and packaging succeeded** on macOS, 15 November 2026. The generated Swift bindings type-check against both iOS device and simulator slices. This does not establish that the complete Proton Mail app builds or runs.

## Pinned inputs

- ProtonMail/clients tag `mail-uniffi-v0.165.4`, commit `6ef4ff39677fd5cbbc7fcd986b6b0d1b773073f7`.
- ProtonMail/proton-crypto-rs commit `abcca7aa806891beea4bb348a3e1781d7fb01d6c`.
- ProtonMail/rust-mail commit `3b6d35b766c10d91b1ffa68e1c5ee47ffca2a67e`, only `3rdparty/muon-proc-0.5.0`.
- `Cargo.lock.public`, SHA-256 `55c4ffd3b502ebab4f2f09a0f01f090c4c21364e80aba3ee8e6fd8a3c3a8d937`.

Exact local source mappings: gopenpgp-sys 0.3.4, proton-crypto 0.12.1, proton-crypto-account 0.18.1, proton-srp 0.8.2, proton-crypto-subtle 0.2.1 and proton-rpgp 0.3.1 come from the pinned crypto repository. muon-proc 0.5.0 comes from the pinned rust-mail vendor directory. The clients mail-muon 1.7.1 fork and its older public proton-srp git revision remain unchanged.

Before marking the initial extracted trees, all 1,468 clients Rust files, 141 crypto Rust files and 10 muon-proc Rust files were compared byte-for-byte with their pinned archives. No Rust implementation was edited. Bootstrap validates archive roots and source-commit markers and refuses nonempty unverified source directories.

## Reproduce

Prerequisites: macOS/Xcode, GitHub CLI with public repository access, Python 3.11+, Rust 1.93.0 with `aarch64-apple-ios` and `aarch64-apple-ios-sim` targets, Go, jq. Verified using Xcode 27.2 and Go 1.27.4. Build script adds the Homebrew Rustup location to PATH without modifying shell settings.

Place these files together in a build directory:
- bootstrap-sources.sh
- reconstruct.py
- build-sdk.sh
- verify-sdk.sh
- Cargo.lock.public
- README-build.md

Run:

```sh
./bootstrap-sources.sh
./build-sdk.sh > build.log 2>&1
./verify-sdk.sh
```

Bootstrap downloads public archives and installs tomli-w 1.2.0 locally into build-tools/. Reconstruction reduces the workspace to 59 required/default-build members, patches dependency paths, restores the resolved lockfile, and adds `--locked` to Cargo compilation, metadata and UniFFI generation.

Proton registry is replaced with an empty local directory before Cargo runs. Missing mappings therefore fail locally rather than contacting Proton infrastructure. Successfully resolved metadata contained 822 packages and no private-source URLs.

## Output and checks

Generated package: `output/0.165.4/Package.swift`, product `proton_app_uniffi`.

Binary: `output/0.165.4/Sources/mail_uniffi_ffi.xcframework`, with `ios-arm64` and `ios-arm64-simulator` slices. Four generated Swift binding files are in `Sources/proton_app_uniffi/`. Debug output totals approximately 3.2 GB.

Verified checks:
1. Cargo `mail-ios-debug` build for `aarch64-apple-ios-sim`, feature `stdout_logging`, `RUSTFLAGS=--cfg forcego`, deployment target 17.2: success.
2. Equivalent Cargo build for `aarch64-apple-ios`: success.
3. `mail-uniffi-bindgen` 0.1.1 with UniFFI 0.29.5 generated Swift from the device static library: success.
4. Upstream framework assembly and `xcodebuild -create-xcframework`: success, exit 0.
5. `swiftc -typecheck` for all generated bindings, module `proton_app_uniffi`, simulator target `arm64-apple-ios17.2-simulator` and matching simulator SDK/framework: exit 0, no diagnostics.
6. Equivalent type-check for device target `arm64-apple-ios17.2` and device SDK/framework: exit 0, no diagnostics.
7. Post-build Cargo.lock exactly matches Cargo.lock.public.

Evidence from this run: build-resume.log, swift-typecheck-simulator.log, swift-typecheck-device.log, metadata.json, reconstruction-report.json. The initial run was interrupted by a computer disconnection; original log is build-before-reconnect.log. After reconnect, no existing compiler process remained, and the incremental build completed.

## Scope and limitations

This reconstructs the upstream build script's default `stdout_logging` feature set. Foundation search, search performance/lab harnesses and historic-search-load optional dependencies are excluded because proton-foundation-search 1.1.2 was not found in the inspected public sources. Cargo otherwise resolves even disabled optional dependencies. Rust produces expected unknown-feature cfg warnings for these removed options; this does not alter active default code.

This is **not a byte-identical upstream release**. It is a locally reconstructed debug SDK using exact public crypto implementations and local dependency paths. No auth or cryptographic algorithm substitutes/stubs were introduced. App-level login, mailbox/network behavior, full app linking and installation were not tested by this SDK task. Independent missing Apple account/payment libraries still prevent claiming a complete app build.

Commit only the six recipe/lock files listed above. Do not commit archives, extracted source trees, build-tools/, target/, metadata/logs or generated frameworks. Integrating the generated local Swift package into the real app is a separate step.

## Integrate into this fork

From the repository root, after building and verifying the SDK:

```sh
mkdir -p ProtonPackages
# Only create this link if the destination does not already exist.
ln -s "$(pwd)/BuildSupport/PublicSDK/output/0.165.4" ProtonPackages/proton_app_uniffi
xcodegen generate
```

Preserve an existing SDK installation rather than replacing it blindly. Generated SDK packages and local links are ignored by Git. This supplies only `proton_app_uniffi`: project generation still needs the separate `PaymentsNG`, `PaymentsUI`, and `ProtonCoreET` Apple packages. See [the production build report](../../PRODUCTION_BUILDABILITY.md).

Build-support scripts are GPL-3.0-or-later. Downloaded dependencies retain their upstream licenses; do not strip their license files.
