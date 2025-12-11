#!/usr/bin/env bash
# Minimal generic recovery build script.
# Assumes repo has been initialized and synced and working directory is repo root.
# Set DEVICE and VARIANT environment variables (e.g. DEVICE=sargo VARIANT=userdebug)

set -euo pipefail
nproc=$(nproc)
echo "Building recovery for device=${DEVICE:-unknown} variant=${VARIANT:-userdebug} with $nproc cores"

# Source the Android build environment
if [ -f build/envsetup.sh ]; then
  # For AOSP/Lineage style builds
  source build/envsetup.sh
else
  echo "Cannot find build/envsetup.sh - are you in an Android tree?"
  exit 2
fi

# Try some common lunch/choosecombo variants. Adjust if your tree uses different names.
if type lunch >/dev/null 2>&1; then
  # recommended combos to try
  combos=(
    "${DEVICE}-recovery-${VARIANT}"
    "${DEVICE}-userdebug"
    "${DEVICE}-user"
    "${DEVICE}-eng"
  )
  for c in "${combos[@]}"; do
    echo "Attempting lunch ${c}..."
    if lunch "${c}" >/dev/null 2>&1; then
      echo "Selected combo: ${c}"
      break
    fi
  done
fi

# Enable ccache
export USE_CCACHE=1
export CCACHE_DIR=${CCACHE_DIR:-$HOME/.ccache}
ccache -M 20G || true
echo "Using ccache at $CCACHE_DIR"

# Build the recovery image; try make targets that recovery projects use
set -x
# Prefer mka if available (parallel make wrapper)
if type mka >/dev/null 2>&1; then
  mka recoveryimage -j${nproc} || mka recovery -j${nproc} || make recoveryimage -j${nproc}
else
  make recoveryimage -j${nproc} || make recovery -j${nproc}
fi
set +x

echo "Build finished. Expected output (common locations):"
echo "  out/target/product/${DEVICE}/recovery.img"
echo "  out/target/product/${DEVICE}/ramdisk-recovery.img"