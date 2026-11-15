#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE/output/0.165.4"
plutil -lint Sources/mail_uniffi_ffi.xcframework/Info.plist
for platform in simulator device; do
  if [[ "$platform" == simulator ]]; then
    sdk=iphonesimulator; target=arm64-apple-ios17.2-simulator; slice=ios-arm64-simulator
  else
    sdk=iphoneos; target=arm64-apple-ios17.2; slice=ios-arm64
  fi
  xcrun swiftc -typecheck -module-name proton_app_uniffi -target "$target" \
    -sdk "$(xcrun --sdk "$sdk" --show-sdk-path)" \
    -F "Sources/mail_uniffi_ffi.xcframework/$slice" Sources/proton_app_uniffi/*.swift \
    > "$BASE/swift-typecheck-$platform.log" 2>&1
  echo "$platform: all generated Swift bindings type-checked"
done
cmp "$BASE/Cargo.lock.public" "$BASE/clients/Cargo.lock"
echo 'Resolved lockfile unchanged'
