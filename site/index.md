---
title: ezkey
description: A macOS menu bar extra for the login Keychain you already have. Local only. No account, no server, no warranty.
---

# ezkey

In the menu bar.

ezkey is a small macOS extra for the login Keychain you already have. No account. No server. No warranty.

## How it works

- **Name** — Keychain Access Name and Where
- **Account** — your Mac user, kept hidden
- **Retrieve** — type part of a name, then pick
- **Reveal** — masked until you ask
- **Copy** — clears in 30 seconds if unchanged

## Build it on your Mac

Requires macOS 14+ and Xcode command-line tools.

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh
```

There is no official downloadable app until a GitHub Release is Developer ID signed and notarized by Apple. If you did not compile it, do not grant it Keychain access. Always Allow is a standing grant to that code signature.

See the [glossary](https://ezkey.app/glossary.md) for Keychain field names.

[Privacy](https://ezkey.app/privacy.md) · [Security](https://ezkey.app/security.md) · [Source](https://github.com/edtadros/ezkey)
