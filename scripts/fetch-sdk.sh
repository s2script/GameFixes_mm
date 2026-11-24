#!/bin/bash
# Fetches the pinned s2sdk, s2sdk-manifests and Metamod:Source into $1 (default /tmp/sdk).
# Used by the Linux container build (scripts/docker-entrypoint.sh) and by the Windows
# CI job, so both build against the same headers.
#
# s2sdk is s2script/s2sdk (branch s2script-cs2), which is checked against every CS2
# build on update day; Source2Mod/s2sdk lagged CS2 build 26879581's new ISource2Server
# slot. Every dependency is pinned to a commit: a branch head that moves can silently
# change the vtable layout the plugin is compiled against. To move a pin, change it here.
set -euo pipefail

SDK_DIR="${1:-/tmp/sdk}"

S2SDK_URL="https://github.com/s2script/s2sdk.git"
S2SDK_REV="577f720ad022d7c9cb12ddeb76ae1c7a5409f60c"            # s2script-cs2, CS2 build 26879581
S2SDK_MANIFESTS_URL="https://github.com/Source2Mod/s2sdk-manifests.git"
S2SDK_MANIFESTS_REV="deab68e08b398b8b70104560fc8761005c4b8754"  # master
MMSOURCE_URL="https://github.com/Source2Mod/metamod-source.git"
MMSOURCE_REV="fa63fbd2cfab0e6b58b84baf68fd0e5bfacafbfc"         # master

# Clone at an exact commit.
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

