# Security

## Do not file public issues for vulnerabilities

Use GitHub's private advisory form:

https://github.com/edtadros/ezkey/security/advisories/new

Do not attach secrets, Keychain dumps, or production service names.

## What ezkey is

ezkey is a local UI for generic passwords in the current user's macOS **login Keychain**. It has no network client, no account, and no telemetry.

## Trust model

- Secrets are stored by macOS, not by ezkey.
- Retrieve happens only after an explicit click.
- macOS Keychain access-control lists still apply. Items created by other programs typically prompt.
- **Always Allow** is a user grant to this app's code signature. It is not something ezkey can give itself.
- Items ezkey creates trust only ezkey. Other programs, including `/usr/bin/security`, get the macOS password prompt when they read the secret. Updates do not rewrite existing access-control lists.
- The app is **not sandboxed**. A sandbox would place items in an application Keychain that `security` cannot see.

## What to report

Useful: unexpected Keychain writes, secret values appearing in logs or files, clipboard clearing failures, code the install skill's review should have caught but did not.

Not useful: "Keychain asked me for a password" (that is macOS working).

## Supported versions

Only the newest `v*` release tag.
