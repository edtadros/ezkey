---
title: About — ezkey
description: ezkey is a local macOS menu bar extra for the login Keychain. It is not a hosted password manager.
---

# About

ezkey is a small open-source macOS application. It lives in the menu bar and talks to the login Keychain that macOS already keeps on the computer. It does not create an account, it does not run a backend, and it does not send secrets off the machine.

The product exists because the security command-line tool and Keychain Access already store generic passwords, and a compact extra is easier for day-to-day save and retrieve. Name in ezkey is the same string Keychain Access shows as Name and Where. Account is the logged-in Mac user and is not shown in the extra.

The software is provided as-is, without warranty or a support contract. The source is public so anyone can read the Keychain calls, build the app locally, and decide whether to grant it access. There is no official unsigned download. Until a GitHub Release is Developer ID signed and notarized, the supported path is clone and run `./scripts/install.sh`. That copies `ezkey.app` into `/Applications` and turns on Open at Login.

ezkey is not a hosted password manager, not a browser extension, and not a sync service. It does not replace 1Password, iCloud Keychain, or the security CLI. It is a local extra for generic-password items you already keep in login.keychain-db.

See the [glossary](https://ezkey.app/glossary.md) for field names, [security](https://ezkey.app/security.md) for Always Allow, [guides](https://ezkey.app/guides.md) for how to save API keys on a Mac, and [contact](https://ezkey.app/contact.md) for how to report issues.
