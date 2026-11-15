#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "$(dirname "$0")"
fetch() {
  local repo="$1" ref="$2" archive="$3" dest="$4" strip="$5" subpath="${6:-}"
  local marker="$dest/.source-commit"
  if [[ -d "$dest" && -n "$(ls -A "$dest")" ]]; then
    if [[ ! -f "$marker" || "$(cat "$marker")" != "$repo $ref" ]]; then
      echo "Refusing nonempty unverified source directory: $dest" >&2; exit 1
    fi
    return
  fi
  if [[ ! -s "$archive" ]]; then gh api "repos/$repo/tarball/$ref" > "$archive"; fi
  local expected="${repo/\//-}-${ref:0:7}/"
  local actual
  actual=$(tar -tzf "$archive" | sed -n '1p')
  [[ "$actual" == "$expected" ]] || { echo "Archive source mismatch: $archive" >&2; exit 1; }
  mkdir -p "$dest"
  if [[ -n "$subpath" ]]; then
    tar -xzf "$archive" --strip-components="$strip" -C "$dest" "$subpath"
  else
    tar -xzf "$archive" --strip-components="$strip" -C "$dest"
  fi
  printf '%s %s\n' "$repo" "$ref" > "$marker"
}
fetch ProtonMail/clients 6ef4ff39677fd5cbbc7fcd986b6b0d1b773073f7 clients.tar.gz clients 1
fetch ProtonMail/proton-crypto-rs abcca7aa806891beea4bb348a3e1781d7fb01d6c crypto.tar.gz crypto 1
fetch ProtonMail/rust-mail 3b6d35b766c10d91b1ffa68e1c5ee47ffca2a67e rust-mail.tar.gz rust-mail-vendor 2 '*/3rdparty/muon-proc-0.5.0'
python3 -m pip install --target build-tools tomli-w==1.2.0
python3 reconstruct.py
