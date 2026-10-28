#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ezkey"
DEFAULT_ENTITLEMENTS="$ROOT_DIR/Resources/ezkey.entitlements"
TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.team-identifier' "$DEFAULT_ENTITLEMENTS")"
APPLICATION_ID="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.application-identifier' "$DEFAULT_ENTITLEMENTS")"
BUNDLE_ID="${APPLICATION_ID#"$TEAM_ID."}"
BUILD_ROOT="$ROOT_DIR/build"
APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/${APP_NAME}"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
LICENSE_FILE="$ROOT_DIR/LICENSE"
SIGN_IDENTITY="${EZKEY_SIGN_IDENTITY:-}"
ENTITLEMENTS="${EZKEY_ENTITLEMENTS:-$DEFAULT_ENTITLEMENTS}"
PROFILE="${EZKEY_PROFILE:-}"
NOTARY_PROFILE="${EZKEY_NOTARY_PROFILE:-}"

cd "$ROOT_DIR"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  SIGN_IDENTITY=""
fi
if [[ -n "$NOTARY_PROFILE" && -z "$SIGN_IDENTITY" ]]; then
  echo "EZKEY_NOTARY_PROFILE requires EZKEY_SIGN_IDENTITY; cannot notarize an ad hoc build." >&2
  exit 1
fi
if [[ -n "$SIGN_IDENTITY" ]]; then
  if [[ "$ENTITLEMENTS" != "none" && ! -f "$ENTITLEMENTS" ]]; then
    echo "Entitlements file not found: $ENTITLEMENTS" >&2
    exit 1
  fi
  if [[ -n "$PROFILE" && ! -f "$PROFILE" ]]; then
    echo "Provisioning profile not found: $PROFILE" >&2
    exit 1
  fi
  if [[ "$ENTITLEMENTS" != "none" && -z "$PROFILE" ]]; then
    echo "Warning: Developer ID signing with restricted keychain-access-groups needs an embedded provisioning profile (EZKEY_PROFILE), or AMFI kills the app at launch." >&2
  fi
fi

sign_app() {
  local app="$1"
  if [[ -n "$SIGN_IDENTITY" ]]; then
    if [[ -n "$PROFILE" ]]; then
      cp "$PROFILE" "$app/Contents/embedded.provisionprofile"
    fi
    local -a options=(--force --options runtime --timestamp)
    if [[ "$ENTITLEMENTS" != "none" ]]; then
      options+=(--entitlements "$ENTITLEMENTS")
    fi
    codesign "${options[@]}" --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$app"
    echo "Signed with $SIGN_IDENTITY"
  else
    codesign --force --sign - --identifier "$BUNDLE_ID" "$app"
    echo "Ad-hoc signed for local use. Do not distribute this binary."
  fi
  codesign --verify --deep --strict "$app"
}

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

sign_app "$APP_DIR"

echo "Packaged app: $APP_DIR"

if [[ "${SKIP_VERIFY:-0}" != "1" ]]; then
  echo "Running signed-app Keychain self-test…"
  "$APP_DIR/Contents/MacOS/${APP_NAME}" --self-test
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  NOTARY_ZIP="$BUILD_ROOT/${APP_NAME}-notary.zip"
  rm -f "$NOTARY_ZIP"
  ditto -c -k --keepParent "$APP_DIR" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_DIR"
  codesign --verify --deep --strict "$APP_DIR"
fi

if [[ "${SKIP_INSTALL:-0}" != "1" ]]; then
  INSTALL_DIR="${EZKEY_INSTALL_DIR:-/Applications}"
  mkdir -p "$INSTALL_DIR"
  INSTALLED="$INSTALL_DIR/${APP_NAME}.app"
  rm -rf "$INSTALLED"
  ditto "$APP_DIR" "$INSTALLED"
  if [[ -n "$NOTARY_PROFILE" ]]; then
    codesign --verify --deep --strict "$INSTALLED"
  else
    sign_app "$INSTALLED"
  fi
  echo "Installed: $INSTALLED"
  if [[ "$INSTALLED" == "/Applications/${APP_NAME}.app" && -d "$HOME/Applications/${APP_NAME}.app" ]]; then
    rm -rf "$HOME/Applications/${APP_NAME}.app"
    echo "Removed the earlier copy in ~/Applications."
  fi

  if [[ "${SKIP_LAUNCH:-0}" != "1" ]]; then
    pkill -x ezkey >/dev/null 2>&1 || true
    open "$INSTALLED"
    echo "Opened ${INSTALLED}. Open at Login is on unless you turn it off in the panel."
  fi
fi
