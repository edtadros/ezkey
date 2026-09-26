# Contributing

## Secrets

Do not put API keys, passwords, Keychain dumps, or real service/account pairs in issues, pull requests, or commit messages. Tests must use the `ezkey.test.` service prefix only.

## Pull requests

Non-maintainers should open a PR. Do not include personal filesystem paths, or signing identities.

CI must pass (`ci-gate`).

## Scope

ezkey stays a local Keychain UI. Do not add network calls, analytics, accounts, iCloud sync, or auto-update.
