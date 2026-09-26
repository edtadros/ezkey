# ezkey

A small native macOS menu bar app for saving, updating, and retrieving secrets in the **login Keychain**. It is local software. It is not a hosted password manager.

**Provided as-is, without warranty or liability.** See [LICENSE](LICENSE) and [DISCLAIMER.md](DISCLAIMER.md). Site: [ezkey.app](https://ezkey.app).

ezkey talks to the same file-based Keychain as:

```sh
security add-generic-password -U -a "$USER" -s "your-service-name" -w "$SECRET" "$HOME/Library/Keychains/login.keychain-db"

security find-generic-password -a "$USER" -s "your-service-name" -w "$HOME/Library/Keychains/login.keychain-db"
```

## How to get it

**Build from source.** That is the only supported path. There is no prebuilt app.

Ask your agent:

```
Install ezkey on this Mac. Follow https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md. Show me the disclaimer first. Clone the newest release tag and review the code with the checklist in that file before building. Show me the results and wait for my go-ahead before running ./scripts/install.sh. Do not download a prebuilt app. Do not send Keychain secrets anywhere.
```

The [skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) has the agent clone the newest `v*` tag, run six checks (no third-party packages, no network code, no other programs launched, no stray output, Keychain calls in one file, install scripts download nothing), read the code, and wait for you. CI runs the same checks on every change, so the skill and the code cannot drift. A review lowers risk. It does not prove the code is safe.

By hand:

```sh
TAG=$(git ls-remote --tags --refs --sort=-v:refname https://github.com/edtadros/ezkey.git 'v*' | head -1 | sed 's#.*refs/tags/##')
git clone --depth 1 --branch "$TAG" https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Requires macOS 14 or later and Xcode 16+ / Swift 6.1 command-line tools.

`install.sh` runs the tests, builds the app, copies it to `/Applications/ezkey.app` (the Applications folder in Finder), opens it, and turns on **Open at Login**. You can turn that off from the panel. The build is ad-hoc signed for your Mac. It was never downloaded, so Gatekeeper does not check it and it needs no notarization. **Do not give your build to other people.**

Look for the shield-and-key icon in the menu bar (often near the notch, not next to Control Center). There is no Dock icon. The mark is Noun Project “VPN” (5544559).

## Use

1. Click the key icon.
2. Choose **Save** or **Retrieve**.
3. Enter a **Name**. That is Keychain Access **Name** and **Where** (they are stored as the same string). Account is the Mac username and is not shown. Example: `my-app-api-token`.
4. **Save** writes a new item. Optional **Notes** are stored as Keychain Access **Comments** (`security add-generic-password -j`). If that pair already exists, you must click **Update**.
5. **Retrieve** looks up an exact name and account when both match. If you type only part of the name (Keychain Access **Name** or **Where**, or the Comments text), ezkey lists matching entries without showing secrets. Click one to retrieve that secret and its notes. Notes are item attributes, not a second password; they show in the clear. macOS may ask for your login Keychain password the first time ezkey reads an item created by another app. After you Allow, the panel returns with the secret masked. **Reveal**, **Hide**, and **Copy** follow. **Always Allow** is a standing grant to this app’s code signature; use it only for a build you compiled. Each rebuild changes the signature, so macOS may ask again after an update.
6. **Quit ezkey** exits. **License** opens the MIT text bundled in the app.

The name may be remembered. Secret values are not. When ezkey saves, it sets Keychain Access **Name** and **Where** to that name and **Account** to the logged-in Mac user.

## What this software does not do

- It does not send secrets, or anything else, off the Mac.
- It does not bypass Keychain prompts.
- It is not sandboxed. A sandbox would store items where `security` cannot see them.
- It does not offer support, backups, or recovery.

## Releases

A release is a `v*` tag. Only the maintainer can create one. See [RELEASING.md](RELEASING.md).

## Security

Report vulnerabilities privately: <https://github.com/edtadros/ezkey/security/advisories/new>

Details: [SECURITY.md](SECURITY.md).
