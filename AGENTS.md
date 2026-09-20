# AGENTS.md

## Project

ezkey is a native macOS menu bar app that saves and retrieves generic passwords in the user's login Keychain. This website is static marketing and documentation for that app.

## Setup

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh
```

Requires macOS 14 or later and Xcode command-line tools. The script runs tests, packages `build/ezkey.app`, and launches it.

## Commands

- `swift test` — unit tests. Disposable Keychain items use the `ezkey.test.` name prefix only.
- `./scripts/build-and-run.sh` — test, package, launch locally (ad-hoc signed).
- `npx wrangler deploy` — publish this website to Cloudflare (`ezkey.app`).
- `./scripts/render-marketing.sh` — snapshot the real SwiftUI panel into `site/images/` (generic example names, no Keychain).

## Conventions

- Do not log or commit secrets.
- Do not add network calls, analytics, or auto-update to the app.
- Public binaries require `scripts/release.sh` with Developer ID and Apple notarization.
- Site copy stays generic. Do not use personal names in examples.
