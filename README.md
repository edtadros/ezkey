# ezkey

A small native macOS menu bar app for saving, updating, and retrieving secrets in the login Keychain. It is a standalone tool, not part of PhishHook.

ezkey talks to the same file-based login Keychain as:

```sh
security add-generic-password -U -a "$USER" -s "phishhook/jev" -w "$SECRET" "$HOME/Library/Keychains/login.keychain-db"

security find-generic-password -a "$USER" -s "phishhook/jev" -w "$HOME/Library/Keychains/login.keychain-db"
```

## Requirements

- macOS 14 Sonoma or later
- Xcode 16+ / Swift 6.2+ command-line tools

## Install and run

```sh
chmod +x scripts/build-and-run.sh
./scripts/build-and-run.sh
```

That runs tests, builds a release binary, packages `build/ezkey.app`, signs it, and launches it. Look for the key icon in the menu bar. There is no Dock icon.

To package without launching:

```sh
SKIP_LAUNCH=1 ./scripts/build-and-run.sh
open build/ezkey.app
```

The key icon may sit on the left of the menu-bar extras (near the notch), not next to Control Center.

`SKIP_TESTS=1` skips `swift test`. `SKIP_VERIFY=1` skips the signed-app `--self-test` against disposable `ezkey.test.*` Keychain items.

Optional: set `EZKEY_SIGN_IDENTITY` to a codesigning name. The script falls back to ad-hoc signing if the default Apple Development identity is missing.

Keep `build/ezkey.app` wherever you like, or drag it to `/Applications`.

## Use

1. Click the key icon.
2. Choose **Save** or **Retrieve**.
3. Enter a **Service** (for example `phishhook/jev`) and **Account** (defaults to your Unix username).
4. **Save** writes a new item. If that service/account pair already exists, ezkey asks you to click **Update** before replacing it.
5. **Retrieve** looks up the exact pair. The secret stays masked until **Reveal**. **Hide** and **Copy** are available after a successful retrieve.
6. **Quit ezkey** exits the app.

Service and account labels are remembered. Secret values are not.

## Signing

A stable signing identity keeps Keychain access-control lists from prompting on every rebuild. Ad-hoc signing works for local use, but macOS may ask again after each new binary.

This app is not sandboxed. Sandboxing would store items in an application keychain that `/usr/bin/security` cannot see.

## Keychain permission prompts

macOS may ask you to allow ezkey to use an item, or to allow `security` to use an item ezkey created. That is normal.

- **Allow** grants that lookup or save.
- **Deny** surfaces “Keychain access denied.”
- **Cancel** surfaces “Keychain access cancelled.”

ezkey does not bypass these prompts. Existing item access controls are left in place on update.

## Security notes

- Secrets live only in the login Keychain.
- ezkey does not log, write, or put secret values in preferences, files, or process arguments.
- Retrieve runs only after you click **Retrieve**.
- Closing the panel clears the save field and any retrieved secret, and drops in-flight lookups.
- **Copy** clears the clipboard after 30 seconds only if it still contains the value ezkey copied.
