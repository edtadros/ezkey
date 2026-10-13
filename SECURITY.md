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
- ezkey never suppresses or bypasses the macOS Keychain password prompt.
- Items ezkey saves trust no app to read the secret, ezkey included. Every read, by ezkey, `/usr/bin/security`, or anything else, asks for your login password, even after **Always Allow**. This is deliberate. macOS would otherwise let ezkey read what it saved without asking, and ezkey has no login of its own, so anyone using your unlocked Mac could read your keys. Names and notes stay readable so search works; only the secret is protected.
- You change a secret from Retrieve: click Update…, enter the new secret or notes, check what changes, then click Replace. Replacing is permanent, asks for your login password, and never happens from the Return key.
- ezkey never deletes keys. To delete one, use Keychain Access.
- Updates do not rewrite existing access-control lists. Items saved by ezkey 1.0.0 keep the macOS default, which lets ezkey read them without a prompt. To protect one, delete it in Keychain Access and save it again in ezkey.
- The app is **not sandboxed**. A sandbox would place items in an application Keychain that `security` cannot see.

## What to report

Useful: unexpected Keychain writes, secret values appearing in logs or files, clipboard clearing failures, code the install skill's review should have caught but did not.

Not useful: "Keychain asked me for a password" (that is macOS working).

## Supported versions

Only the newest `v*` release tag.
