#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ezkey"
BUILD_ROOT="$ROOT_DIR/build"
APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/${APP_NAME}"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
SIGN_IDENTITY="${EZKEY_SIGN_IDENTITY:-Apple Development: Edward Tadros (VDT383H7NN)}"

cd "$ROOT_DIR"

if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  echo "Running tests…"
  swift test --package-path "$ROOT_DIR"
fi

echo "Building release binary…"
swift build -c release --package-path "$ROOT_DIR"

echo "Packaging ${APP_NAME}.app…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/${APP_NAME}"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"
xattr -cr "$APP_DIR" >/dev/null 2>&1 || true

if codesign --force --sign "$SIGN_IDENTITY" --identifier com.proticom.ezkey "$APP_DIR" >/dev/null 2>&1; then
  echo "Signed with $SIGN_IDENTITY"
else
  echo "Development identity unavailable; signing ad-hoc"
  codesign --force --sign - --identifier com.proticom.ezkey "$APP_DIR" >/dev/null
fi

echo "Packaged app: $APP_DIR"

if [[ "${SKIP_VERIFY:-0}" != "1" ]]; then
  echo "Running signed-app Keychain self-test…"
  "$APP_DIR/Contents/MacOS/${APP_NAME}" --self-test
fi

if [[ "${SKIP_LAUNCH:-0}" != "1" ]]; then
  pkill -x ezkey >/dev/null 2>&1 || true
  open "$APP_DIR"
  echo "Launched ezkey. Look for the key icon in the menu bar."
fi
