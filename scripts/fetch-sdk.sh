#!/bin/bash
# Fetches the pinned s2sdk, s2sdk-manifests and Metamod:Source into $1 (default /tmp/sdk)
# and applies patches/s2sdk/*.patch to s2sdk. Used by the Linux container build
# (scripts/docker-entrypoint.sh) and by the Windows CI job, so both build against the
# same headers.
#
# Every dependency is pinned to a commit: a branch head that moves (or, as with
# Source2Mod/s2sdk after CS2 build 26879581, does not move) can silently change the
# vtable layout the plugin is compiled against. To move a pin, change it here, check
# that every patch still applies, and drop the patches upstream now carries.
set -euo pipefail

SDK_DIR="${1:-/tmp/sdk}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

S2SDK_URL="https://github.com/Source2Mod/s2sdk.git"
S2SDK_REV="02e96d47165452419edd68a4932fc59f67799134"            # cs2, 2026-11-13
S2SDK_MANIFESTS_URL="https://github.com/Source2Mod/s2sdk-manifests.git"
S2SDK_MANIFESTS_REV="deab68e08b398b8b70104560fc8761005c4b8754"  # master
MMSOURCE_URL="https://github.com/Source2Mod/metamod-source.git"
MMSOURCE_REV="fa63fbd2cfab0e6b58b84baf68fd0e5bfacafbfc"         # master

# Clone at an exact commit. core.autocrlf off so the patches apply on Windows too.
fetch() {
  local url="$1" rev="$2" dir="$3"
  git -c core.autocrlf=false init -q "$dir"
  git -C "$dir" config core.autocrlf false
  git -C "$dir" remote add origin "$url"
  git -C "$dir" fetch -q --depth 1 origin "$rev"
  git -C "$dir" checkout -q FETCH_HEAD
  git -C "$dir" -c core.autocrlf=false submodule update -q --init --recursive --depth 1
  echo "  $(basename "$dir") at $(git -C "$dir" rev-parse --short HEAD)"
}

echo "=== Fetching pinned SDKs into $SDK_DIR ==="
rm -rf "$SDK_DIR"
mkdir -p "$SDK_DIR"
fetch "$S2SDK_URL" "$S2SDK_REV" "$SDK_DIR/s2sdk"
fetch "$S2SDK_MANIFESTS_URL" "$S2SDK_MANIFESTS_REV" "$SDK_DIR/s2sdk-manifests"
fetch "$MMSOURCE_URL" "$MMSOURCE_REV" "$SDK_DIR/metamod-source"

shopt -s nullglob
for p in "$REPO_ROOT"/patches/s2sdk/*.patch; do
  echo "  applying $(basename "$p")"
  git -C "$SDK_DIR/s2sdk" apply --whitespace=nowarn "$p"
done
