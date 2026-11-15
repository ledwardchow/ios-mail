#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
export PATH=/opt/homebrew/opt/rustup/bin:$PATH
cd "$BASE/clients/project/mail/rust"
rust-build/build_ios_framework_uniffi.sh mail-uniffi ./mail/mail-uniffi/uniffi.toml "$BASE/output" mail-ios-debug
