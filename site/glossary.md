---
title: Glossary — ezkey
description: Names for Keychain fields and related ezkey terms.
---

# Glossary

- **Name** — Keychain Access Name. ezkey stores the same string as Where (the generic-password service).
- **Account** — Keychain account attribute. ezkey always uses the logged-in Mac username and does not show the field.
- **Where** — Keychain Access field for the service (`security add-generic-password -s`).
- **login Keychain** — `~/Library/Keychains/login.keychain-db` on macOS.
- **Always Allow** — a macOS grant that lets this app’s code signature read a Keychain item without asking again.
- **Retrieve** — look up an item by name; partial names list matches without showing the secret until you pick one.
