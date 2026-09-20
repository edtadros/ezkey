# ezkey

A small native macOS menu bar app for saving, updating, and retrieving secrets in the **login Keychain**. It is local software. It is not a hosted password manager.

**Provided as-is, without warranty or liability.** See [LICENSE](LICENSE) and [DISCLAIMER.md](DISCLAIMER.md). Site: [ezkey.app](https://ezkey.app).

ezkey talks to the same file-based Keychain as:

```sh
security add-generic-password -U -a "$USER" -s "your-service-name" -w "$SECRET" "$HOME/Library/Keychains/login.keychain-db"

security find-generic-password -a "$USER" -s "your-service-name" -w "$HOME/Library/Keychains/login.keychain-db"
```

## How to get it

**Build from source.** That is the supported path.

```sh
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh
```

Requires macOS 14 or later and Xcode 16+ / Swift 6.1 command-line tools.

The script packages `build/ezkey.app` and ad-hoc signs it for this machine. **Do not give that binary to other people.** A distributable zip exists only if `scripts/release.sh` succeeds at Developer ID signing **and** Apple notarization. CI never attaches an `.app`.

Look for the shield-and-key icon in the menu bar (often near the notch, not next to Control Center). There is no Dock icon. The mark is Noun Project “VPN” (5544559).

## Use

1. Click the key icon.
2. Choose **Save** or **Retrieve**.
3. Enter a **Name**. That is Keychain Access **Name** and **Where** (they are stored as the same string). Account is the Mac username and is not shown. Example: `my-app-api-token`.
4. **Save** writes a new item. Optional **Notes** are stored as Keychain Access **Comments** (`security add-generic-password -j`). If that pair already exists, you must click **Update**.
5. **Retrieve** looks up an exact name and account when both match. If you type only part of the name (Keychain Access **Name** or **Where**, or the Comments text), ezkey lists matching entries without showing secrets. Click one to retrieve that secret and its notes. Notes are item attributes, not a second password; they show in the clear. macOS may ask for your login Keychain password the first time ezkey reads an item created by another app. After you Allow, the panel returns with the secret masked. **Reveal**, **Hide**, and **Copy** follow. **Always Allow** is a standing grant to this app’s code signature; use it only for a build you compiled or a notarized GitHub Release.
6. **Quit ezkey** exits. **License** opens the MIT text bundled in the app.

The name may be remembered. Secret values are not. When ezkey saves, it sets Keychain Access **Name** and **Where** to that name and **Account** to the logged-in Mac user.

## What this software does not do

- It does not send secrets, or anything else, off the Mac.
- It does not bypass Keychain prompts.
- It is not sandboxed. A sandbox would store items where `security` cannot see them.
- It does not offer support, backups, or recovery.

## Signing

Local builds are ad-hoc unless you set `EZKEY_SIGN_IDENTITY`. Public binaries must use `scripts/release.sh` with:

- `EZKEY_SIGN_IDENTITY` — `Developer ID Application: Name (TEAMID)`
- `EZKEY_NOTARY_PROFILE` — a `notarytool` keychain profile

Until both exist, there is no official download.

## Security

Report vulnerabilities privately: <https://github.com/edtadros/ezkey/security/advisories/new>

Details: [SECURITY.md](SECURITY.md).
