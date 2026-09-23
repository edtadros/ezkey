# AGENTS.md

## Project

ezkey is a native macOS menu bar app that saves and retrieves generic passwords in the user's login Keychain. This website is static marketing and documentation for that app.

## Setup

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Requires macOS 14 or later and Xcode command-line tools. `install.sh` runs tests, copies `/Applications/ezkey.app`, opens it, and turns on Open at Login.

## Commands

- `swift test` — unit tests. Disposable Keychain items use the `ezkey.test.` name prefix only.
- `./scripts/install.sh` — install into `/Applications` and open (ad-hoc signed).
- `./scripts/build-and-run.sh` — same script `install.sh` runs. `SKIP_INSTALL=1` packages `build/ezkey.app` only.
- `npx wrangler deploy` — publish this website to Cloudflare (`ezkey.app`).
- `npx github:edtadros/ezkey` — print disclaimer and clone/build steps (does not touch Keychain).
- `node --experimental-strip-types --test tests/site/worker.test.ts` — site worker tests.

## Conventions

- Do not log or commit secrets.
- Do not add network calls, analytics, or auto-update to the app.
- Public binaries require `scripts/release.sh` with Developer ID and Apple notarization.
- Site copy stays generic. Do not use personal names in examples.
