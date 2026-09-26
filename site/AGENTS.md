# AGENTS.md

## Project

ezkey is a native macOS menu bar app that saves and retrieves generic passwords in the user's login Keychain. This website is static marketing and documentation for that app.

## Setup

```
git clone --depth 1 --branch <tag> https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Replace `<tag>` with the newest `v*` release tag. To review the code before building, follow the build-ezkey skill: https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md

Requires macOS 14 or later and Xcode command-line tools. `install.sh` runs tests, builds, runs a Keychain self-test on `ezkey.test.*` items, copies `/Applications/ezkey.app`, opens it, and turns on Open at Login.

## Commands

- `swift test` — unit tests. Disposable Keychain items use the `ezkey.test.` name prefix only.
- `./scripts/install.sh` — install into `/Applications` and open.
- `./scripts/build-and-run.sh` — same script `install.sh` runs. `SKIP_INSTALL=1` packages `build/ezkey.app` only.
- `npx wrangler deploy` — publish this website to Cloudflare (`ezkey.app`).
- `node --experimental-strip-types --test tests/site/worker.test.ts` — site worker tests.

## Conventions

- Do not log or commit secrets.
- Do not add network calls, analytics, or auto-update to the app.
- Install is always a build from source at the newest `v*` release tag. Do not add binary downloads, npm packages, or Homebrew formulas.
- Site copy stays generic. Do not use personal names in examples.
