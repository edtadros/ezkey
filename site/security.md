---
title: Security — ezkey
description: How ezkey uses the login Keychain, and how to report a problem privately.
---

# Security

macOS still owns the Keychain. ezkey is a front door, not a vault.

Report vulnerabilities privately via [GitHub security advisories](https://github.com/edtadros/ezkey/security/advisories/new). Do not open a public issue and do not attach secrets.

## How access works

When ezkey reads an item another program created, macOS may ask for your login Keychain password. That prompt is the operating system. ezkey cannot suppress it.

**Always Allow** means: trust this app’s code signature for that item. A later ezkey signed with the same Developer ID can then read it without asking again. A random unsigned download cannot honestly claim that trust, and you should not give it.

## What you should install

- Source from [github.com/edtadros/ezkey](https://github.com/edtadros/ezkey), built on your Mac, or
- A GitHub Release whose zip is Developer ID signed, Apple-notarized, and whose SHA-256 matches the published checksum.

CI on GitHub runs tests. It does not attach an `.app`. Unsigned CI artifacts are not a release channel.

## Limits

ezkey is not sandboxed. Sandboxing would store items where the `security` CLI cannot see them. The source is public so you can read the Keychain calls yourself. There is still no warranty that it is free of defects.

See the [glossary](https://ezkey.app/glossary.md).
