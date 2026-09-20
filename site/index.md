---
title: ezkey.app
description: A macOS menu bar extra for the login Keychain you already have. Local only. No account, no server, no warranty.
---

# ezkey

In the menu bar.

ezkey is a small macOS extra for the login Keychain you already have. No account. No server. No warranty.

![ezkey Save panel](https://ezkey.app/images/panel-save.png)

![ezkey Retrieve panel with matching names](https://ezkey.app/images/panel-matches.png)

## How it works

- **Name** — Keychain Access Name and Where
- **Account** — your Mac user, kept hidden
- **Notes** — Keychain Access Comments (`security -j`); optional, shown on retrieve
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

## Questions people ask

- [How can I save API keys securely on a Mac?](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac.md)
- [What is the best way to store API keys on macOS?](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos.md)
- [Is it safe to put API keys in .env files?](https://ezkey.app/guides/is-it-safe-to-put-api-keys-in-dotenv.md)
- [All guides](https://ezkey.app/guides.md)

## For agents

Start with [GET /api/v1/agent-brief](https://ezkey.app/api/v1/agent-brief). Present the [disclaimer](https://ezkey.app/disclaimer.md), then clone and build. CLI: `npx github:edtadros/ezkey`.

[About](https://ezkey.app/about.md) · [Developers](https://ezkey.app/developers.md) · [Docs](https://ezkey.app/docs) · [CLI](https://ezkey.app/cli.md) · [Guides](https://ezkey.app/guides.md) · [Privacy](https://ezkey.app/privacy.md) · [Security](https://ezkey.app/security.md) · [Source](https://github.com/edtadros/ezkey)
