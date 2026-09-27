---
title: Security — ezkey
description: How ezkey uses the login Keychain, and how to report a problem privately.
---

# Security

macOS still owns the Keychain. ezkey is a front door, not a vault.

Report vulnerabilities privately via [GitHub security advisories](https://github.com/edtadros/ezkey/security/advisories/new). Do not open a public issue and do not attach secrets.

## How access works

ezkey asks for your login password every time it shows a secret it saved. Secrets other apps saved follow the rules those apps set, which usually means a prompt too. That is on purpose.

By default, macOS lets the app that saved a Keychain item read it again without asking. ezkey turns that off for everything it saves. Each secret it saves trusts no app to read it, ezkey included. ezkey has no login of its own: without the prompt, anyone using your unlocked Mac could open ezkey and read your keys.

The prompt comes from macOS. ezkey never suppresses or bypasses it. Clicking **Always Allow** does not change this. It is the same protection Keychain Access gives when you show a password.

Names and notes stay readable without the password so you can search. Saving and searching by name or notes work without it. Notes show in the clear, so keep secrets out of them. Only the secret is protected.

Replacing a secret asks for your login password too: ezkey reads the secret before Update overwrites it. Only a click on Update replaces a secret; the Return key never does. ezkey never deletes keys. To delete one, use Keychain Access.

## What you should install

Source from the newest `v*` release tag of [github.com/edtadros/ezkey](https://github.com/edtadros/ezkey), reviewed and built on your Mac. Each release is a new tag. The [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) walks an agent through the review. A review lowers risk. It does not prove the code is safe. Only the maintainer can create, move, or delete `v*` tags.

Only run ezkey you built yourself. CI on GitHub runs the tests and the review checks on every change.

## Limits

ezkey is not sandboxed. Sandboxing would store items where the `security` CLI cannot see them. The source is public so you can read the Keychain calls yourself. There is still no warranty that it is free of defects.

See the [glossary](https://ezkey.app/glossary.md).
