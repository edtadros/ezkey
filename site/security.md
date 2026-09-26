---
title: Security — ezkey
description: How ezkey uses the login Keychain, and how to report a problem privately.
---

# Security

macOS still owns the Keychain. ezkey is a front door, not a vault.

Report vulnerabilities privately via [GitHub security advisories](https://github.com/edtadros/ezkey/security/advisories/new). Do not open a public issue and do not attach secrets.

## How access works

When ezkey reads an item another program created, macOS may ask for your login Keychain password. That prompt is the operating system. ezkey cannot suppress it.

**Always Allow** means: trust the code signature of the ezkey build you compiled for that item. A local build is ad-hoc signed for that Mac. Each rebuild changes the signature, so macOS may ask again after an update. A random downloaded `.app` cannot honestly claim that trust, and you should not give it.

## What you should install

Source from the newest `v*` release tag of [github.com/edtadros/ezkey](https://github.com/edtadros/ezkey), reviewed and built on your Mac. That is the only supported version. The [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) walks an agent through the review. A review lowers risk. It does not prove the code is safe. Only the maintainer can create, move, or delete `v*` tags.

There is no prebuilt app. A local build is not notarized and does not need to be: it was never downloaded, so Gatekeeper does not check it. CI on GitHub runs tests. It does not attach an `.app`. CI artifacts are not a release channel.

## Limits

ezkey is not sandboxed. Sandboxing would store items where the `security` CLI cannot see them. The source is public so you can read the Keychain calls yourself. There is still no warranty that it is free of defects.

See the [glossary](https://ezkey.app/glossary.md).
