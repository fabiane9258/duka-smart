#!/usr/bin/env bash
# Run Flutter with the git-based SDK in ~/development/flutter (recommended).
# Falls back to the Snap workaround only if that SDK is missing.
set -euo pipefail

cd "$(dirname "$0")"

GIT_SDK="$HOME/development/flutter"
FLUTTER_BIN="$GIT_SDK/bin/flutter"

if [[ -x "$FLUTTER_BIN" ]]; then
  export PATH="$GIT_SDK/bin:$PATH"
  exec flutter "$@"
fi

# --- Legacy: Snap Flutter (llvm-10 in snap has no ld.lld next to clang++) ---
SDK="${FLUTTER_SDK:-$HOME/snap/flutter/common/flutter}"
BOOTSTRAP="$SDK/bin/internal/bootstrap.sh"
FLUTTER_BIN="$SDK/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]] || [[ ! -f "$BOOTSTRAP" ]]; then
  echo "Flutter SDK not found."
  echo "Install the official SDK: https://docs.flutter.dev/get-started/install/linux"
  echo "Expected: $FLUTTER_BIN"
  exit 1
fi

LLVM_BIN=""
for v in 20 19 18 17 16 15; do
  d="/usr/lib/llvm-$v/bin"
  if [[ -x "$d/ld.lld" ]]; then
    LLVM_BIN="$d"
    break
  fi
done
if [[ -z "$LLVM_BIN" ]]; then
  echo "Could not find /usr/lib/llvm-*/bin/ld.lld — install: sudo apt install lld clang"
  exit 1
fi

NEW_PATH_LINE="export PATH=${LLVM_BIN}:/usr/bin:/bin:\$SNAP/usr/bin:\$SNAP/bin:\$SNAP_USER_COMMON/flutter/bin:\$PATH"
sed -i "s|^export PATH=\$SNAP/usr/bin:\$SNAP/bin:\$SNAP_USER_COMMON/flutter/bin:\$PATH\$|${NEW_PATH_LINE}|" "$BOOTSTRAP"

exec "$FLUTTER_BIN" "$@"
