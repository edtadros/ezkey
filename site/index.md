---
title: ezkey.app
description: A macOS menu bar extra for the login Keychain you already have. Local only. No account, no server, no warranty.
---

# ezkey

Ask your agent to install ezkey.

A menu-bar extra for the login Keychain on this Mac. No account, no server, no prebuilt app. Source: [github.com/edtadros/ezkey](https://github.com/edtadros/ezkey).

```
Install ezkey on this Mac. Follow https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md. Show me the disclaimer first. Clone the newest release tag and review the code with the checklist in that file before building. Show me the results and wait for my go-ahead before running ./scripts/install.sh. Do not download a prebuilt app. Do not send Keychain secrets anywhere.
```

![ezkey Save panel](https://ezkey.app/images/panel-save.png)

![ezkey Retrieve panel with matching names](https://ezkey.app/images/panel-matches.png)

## How it works

- **Name** — Keychain Access Name and Where
- **Account** — your Mac user, kept hidden
- **Notes** — Keychain Access Comments (`security -j`); optional, shown on retrieve
- **Retrieve** — type part of a name, then pick
- **Reveal** — masked until you ask
- **Copy** — clears in 30 seconds if unchanged

## Install

Requires macOS 14+ and Xcode command-line tools.

`./scripts/install.sh` copies the app to `/Applications/ezkey.app`, opens it, and turns on Open at Login. Turn that off from the ezkey panel. There is no Dock icon.

```
git clone --depth 1 --branch <tag> https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Replace `<tag>` with the newest `v*` release tag. Only the maintainer can create, move, or delete those tags. To review the code before building, follow the [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md).

There is no prebuilt app. A local build is ad-hoc signed for this Mac. It is not notarized and does not need to be: it was never downloaded, so Gatekeeper does not check it. Always Allow is a standing grant to the code signature of the build you compiled. Each rebuild changes that signature, so macOS may ask again after an update.

See the [glossary](https://ezkey.app/glossary.md) for Keychain field names.

## Questions people ask

- [How can I save API keys securely on a Mac?](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac.md)
- [What is the best way to store API keys on macOS?](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos.md)
- [Is it safe to put API keys in .env files?](https://ezkey.app/guides/is-it-safe-to-put-api-keys-in-dotenv.md)
- [All guides](https://ezkey.app/guides.md)

## For agents

Follow the [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md). Present the [disclaimer](https://ezkey.app/disclaimer.md), clone the newest release tag, run the review, and show the results. Run `./scripts/install.sh` only after the human says go. That copies the app to `/Applications/ezkey.app` and turns on Open at Login. Summary: [GET /api/v1/agent-brief](https://ezkey.app/api/v1/agent-brief).

[About](https://ezkey.app/about.md) · [Developers](https://ezkey.app/developers.md) · [Docs](https://ezkey.app/docs) · [CLI](https://ezkey.app/cli.md) · [Guides](https://ezkey.app/guides.md) · [Privacy](https://ezkey.app/privacy.md) · [Security](https://ezkey.app/security.md) · [Source](https://github.com/edtadros/ezkey)
