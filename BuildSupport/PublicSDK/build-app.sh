#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
test -f ProtonPackages/proton_app_uniffi/Package.swift || { echo 'Build and link the public SDK first; see README-build.md.' >&2; exit 1; }
xcodegen generate
PUBLIC_SOURCE_BUILD=YES xcodebuild -project ProtonMail.xcodeproj -scheme ProtonMail \
  -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${DERIVED_DATA:-$ROOT/tmp/public-app-build}" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM= PUBLIC_SOURCE_BUILD=YES IPHONEOS_DEPLOYMENT_TARGET=17.2 ARCHS=arm64 build "$@"
