#!/bin/bash
set -e

git submodule update --init --recursive

# SEMVER comes in from the CI, whose version job resolves the tag -- on the
# pushbuild.txt path it is not on HEAD yet, so git describe cannot see it. A
# tag push and a local build still find it on HEAD.
if [ -n "${SEMVER:-}" ]; then
  export SEMVER
  echo "=== Version: $SEMVER (from the environment) ==="
elif SEMVER="$(git describe --tags --exact-match 2>/dev/null)"; then
  export SEMVER
  echo "=== Version: $SEMVER (tag on HEAD) ==="
else
  unset SEMVER
fi

export GITHUB_SHA_SHORT="$(git rev-parse --short HEAD)"

### --- Download s2sdk + Metamod-Source ------------------------------------
# Pinned commits plus patches/s2sdk/*.patch -- see scripts/fetch-sdk.sh.
SDK_DIR="/tmp/sdk"
S2SDK_DIR="$SDK_DIR/s2sdk"
S2SDK_MANIFESTS_DIR="$SDK_DIR/s2sdk-manifests"
MMSOURCE_DIR="$SDK_DIR/metamod-source"

bash ./scripts/fetch-sdk.sh "$SDK_DIR"

### --- Export env vars for CMake ------------------------------------------
export S2SDK="$S2SDK_DIR"
export MMSOURCE_DEV="$MMSOURCE_DIR"

echo "Using S2SDK=$S2SDK"
echo "Using MMSOURCE_DEV=$MMSOURCE_DEV"

### --- Build ---------------------------------------------------------------
echo "=== Starting build ==="

rm -rf build
mkdir build
cd build

pwd
python ../configure.py \
  --enable-optimize \
  --sdks cs2 \
  --mms_path=$MMSOURCE_DEV \
  --s2sdk-manifests=$S2SDK_MANIFESTS_DIR
ambuild

echo "=== DONE ==="
