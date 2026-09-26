# AGENTS.md

## Project

ezkey is a native macOS menu bar app that saves and retrieves generic passwords in the user's login Keychain. This website is static marketing and documentation for that app.

## Setup

To install ezkey for a user, follow https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md. Clone the newest `v*` tag, run the review there, show the human the results, and run `./scripts/install.sh` only after they approve.

Requires macOS 14 or later and Xcode command-line tools. `install.sh` runs tests, copies `/Applications/ezkey.app`, opens it, and turns on Open at Login.

## Commands

- `swift test` — unit tests. Disposable Keychain items use the `ezkey.test.` name prefix only.
- `./scripts/install.sh` — install into `/Applications` and open.
- `./scripts/build-and-run.sh` — same script `install.sh` runs. `SKIP_INSTALL=1` packages `build/ezkey.app` only.
- `npx wrangler@4.61.1 deploy` — publish this website to Cloudflare (`ezkey.app`). Deploys are by hand from `master` after a merge; there is no deploy workflow. Check the live site afterward.
- `node --experimental-strip-types --test tests/site/review-checklist.test.ts` — the skill's review commands must match the code. Update the skill and this test together.
- `node --experimental-strip-types --test tests/site/worker.test.ts` — site worker tests.
- `./scripts/render-marketing.sh` — snapshot the real SwiftUI panel into `site/images/` (generic example names, no Keychain).

## Conventions

- Do not log or commit secrets.
- Do not add network calls, analytics, or auto-update to the app.
- Install is source-only, from a `v*` tag.
- Do not mention Developer ID, notarization, or Gatekeeper in user-facing copy. ezkey will never have a Developer ID.
- Keep the site in step with the app. Any change to behavior, the panel, install, the agent prompt, or docs updates in the same PR: the `site/*.md` and `.html` pairs, guides (`python3 scripts/render_guides.py`), `site/llms*.txt`, the agent brief in `src/`, the install skill (and its digest), and screenshots (`./scripts/render-marketing.sh`).
- Site copy stays generic. Do not use personal names in examples.
