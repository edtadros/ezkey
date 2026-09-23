#!/bin/zsh
# Build a distributable app. Refuses to emit a public binary unless Developer ID
# signing and Apple notarization both succeed. Does not upload anywhere.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ezkey"
BUNDLE_ID="app.ezkey"
BUILD_ROOT="$ROOT_DIR/build"
APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
DIST_DIR="$BUILD_ROOT/dist"
ZIP_PATH="$DIST_DIR/${APP_NAME}.zip"
SUMS_PATH="$DIST_DIR/SHA256SUMS"

SIGN_IDENTITY="${EZKEY_SIGN_IDENTITY:-}"
NOTARY_PROFILE="${EZKEY_NOTARY_PROFILE:-}"

if [[ -z "$SIGN_IDENTITY" || -z "$NOTARY_PROFILE" ]]; then
  cat >&2 <<'EOF'
Refusing to build a public binary.

Set both:
  EZKEY_SIGN_IDENTITY   Developer ID Application: Name (TEAMID)
  EZKEY_NOTARY_PROFILE  notarytool keychain profile (see `xcrun notarytool store-credentials`)

Until those exist, the supported distribution path is source on GitHub.
Ad-hoc or Apple Development builds are for the machine that compiled them.
EOF
  exit 1
fi

SKIP_LAUNCH=1 SKIP_INSTALL=1 SKIP_VERIFY=1 EZKEY_SIGN_IDENTITY="$SIGN_IDENTITY" \
  "$ROOT_DIR/scripts/build-and-run.sh"

echo "Re-signing with hardened runtime for notarization…"
codesign --force --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  "$APP_DIR"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "Submitting to Apple notary service…"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_DIR"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" | awk '{print $1 "  ezkey.zip"}' > "$SUMS_PATH"

echo "Notarized zip: $ZIP_PATH"
echo "Checksums:    $SUMS_PATH"
echo "Attach these to a GitHub Release. Do not host unsigned copies."
