---
title: macOS Keychain extra for developers — ezkey.app
description: A macOS menu bar extra that reads and writes the same login Keychain generic passwords as security add-generic-password. Local only. MIT. Build from source.
---

# ezkey for developers who already use security(1)

ezkey is for people who already treat the login Keychain as the place for local API tokens and are tired of either Keychain Access or a wall of `security` flags. It is not a cloud vault. You build it. You read the Keychain calls. Items stay in login.keychain-db.

## The developer reality

You have three tokens for one side project and a live key for a client preview. They live in a password manager, a sticky note, and a `.env` that is gitignored except for the time it was not. Keychain Access can hold them, but the UI is built for certificates and Wi-Fi. `security add-generic-password` works until you forget whether the service string had an underscore.

You do not want another subscription. You do want the item to be the same one your deploy script can `find-generic-password`. You want to see a masked value, copy it, and have the pasteboard forget.

Monday looks like this: a webhook signing secret for a local tunnel, a personal OpenAI key, a Stripe test key, and a GitHub token that can push to one repo. None of them belong in the same 1Password vault as your bank. All of them belong in a place `security` can print. Keychain Access can hold them, but you will click Kind, Label, Account, and Where every time. A menu extra with one Name field is the whole product.

If you maintain a `direnv` setup, you still need a canonical store. direnv loads files. Files leak. Keep the live values in the Keychain and, if you must, have a private script call `find-generic-password` into the environment for that directory. ezkey does not replace direnv. It replaces the plaintext file direnv was about to read.

## How ezkey helps

- Save and Retrieve from the menu bar. No Dock icon.
- Name is Keychain Access Name and Where, one field.
- Retrieve by substring, then pick. Secrets stay hidden until you choose.
- Copy clears in 30 seconds if unchanged.
- Same login.keychain-db as the CLI.

The source is https://github.com/edtadros/ezkey. Read `LoginKeychainStore.swift` if you do not trust marketing pages. Tests live in `Tests/EZKeyCoreTests` and use an `ezkey.test.` name prefix. CI runs `swift test` on macos-15. It does not attach an `.app`. If a random Actions artifact offers you a binary, do not grant it Keychain access.

## What it will not do

It will not rotate keys at OpenAI. It will not sync to a phone. It will not hide from a process running as you. It will not replace 1Password for your bank. It will not ship a notarized binary until someone runs `scripts/release.sh` with Developer ID. Those are not missing checkboxes. They are the product boundary. See [anti-cloud local keys](/for/local-api-keys/).

## Start from source

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Requires macOS 14+ and Xcode command-line tools. Then follow [how to save API keys securely](/guides/how-to-save-api-keys-securely-on-mac/).

If you already have items from `security add-generic-password`, try Retrieve with part of the service string. If the list is empty, check Account in Keychain Access. ezkey only lists the logged-in Mac user. That is annoying if you used `-a` as a project name. It is also how the extra stays small. Rename or resave if you want the menu extra to see them.

## Related answers

- [security add-generic-password](https://ezkey.app/guides/security-add-generic-password/): Flag map to ezkey fields.
- [ezkey vs Keychain Access](https://ezkey.app/compare/ezkey-vs-keychain-access/): Same database.
- [Best way to store API keys on macOS](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos/): Where a vault still wins.
- [Developers (site API)](https://ezkey.app/developers/): MCP and OpenAPI for this website, not for Keychain.

## Does it work with my existing security CLI items?

If account is your Mac username and you know the service string, Retrieve can find it. Partial names list matches.

## Swift version?

Swift 6.1, macOS 14+, Package.swift in the repo.

## Sandbox?

No. A sandbox would hide items from security(1). That is a deliberate trade.

## CI artifacts?

Tests only. CI does not attach an .app. Unsigned CI zips are not a release.
