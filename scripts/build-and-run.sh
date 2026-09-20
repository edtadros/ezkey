#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ezkey"
BUNDLE_ID="app.ezkey"
BUILD_ROOT="$ROOT_DIR/build"
APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/${APP_NAME}"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
LICENSE_FILE="$ROOT_DIR/LICENSE"
# Local/dev only. Public binaries must go through scripts/release.sh (Developer ID + notary).
SIGN_IDENTITY="${EZKEY_SIGN_IDENTITY:-}"

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
cp "$LICENSE_FILE" "$APP_DIR/Contents/Resources/LICENSE"
for icon in MenuBarIcon.png "MenuBarIcon@2x.png" AppIcon.icns; do
  if [[ -f "$ROOT_DIR/Resources/$icon" ]]; then
    cp "$ROOT_DIR/Resources/$icon" "$APP_DIR/Contents/Resources/$icon"
  fi
done
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"
xattr -cr "$APP_DIR" >/dev/null 2>&1 || true

if [[ -n "$SIGN_IDENTITY" ]]; then
  codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_DIR"
  echo "Signed with $SIGN_IDENTITY"
else
  codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_DIR"
  echo "Ad-hoc signed for local use. Do not distribute this binary."
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
