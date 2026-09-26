---
title: Security — ezkey
description: How ezkey uses the login Keychain, and how to report a problem privately.
---

# Security

macOS still owns the Keychain. ezkey is a front door, not a vault.

Report vulnerabilities privately via [GitHub security advisories](https://github.com/edtadros/ezkey/security/advisories/new). Do not open a public issue and do not attach secrets.

## How access works

macOS asks for your login password when ezkey reads a secret that another app saved. That prompt is the operating system. It can ask again next time, even after you click **Always Allow**.

ezkey does not suppress or work around that prompt. That is on purpose: you get the same protection as Keychain Access, which asks every time you show a password. Secrets you save with ezkey usually open without a prompt.

## What you should install

Source from the newest `v*` release tag of [github.com/edtadros/ezkey](https://github.com/edtadros/ezkey), reviewed and built on your Mac. Each release is a new tag. The [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) walks an agent through the review. A review lowers risk. It does not prove the code is safe. Only the maintainer can create, move, or delete `v*` tags.

Only run ezkey you built yourself. CI on GitHub runs the tests and the review checks on every change.

## Limits

ezkey is not sandboxed. Sandboxing would store items where the `security` CLI cannot see them. The source is public so you can read the Keychain calls yourself. There is still no warranty that it is free of defects.

See the [glossary](https://ezkey.app/glossary.md).
