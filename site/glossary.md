---
title: Glossary — ezkey
description: Names for Keychain fields and related ezkey terms.
---

# Glossary

- **Name** — Keychain Access Name. ezkey stores the same string as Where (the generic-password service).
- **Account** — Keychain account attribute. ezkey always uses the logged-in Mac username and does not show the field.
- **Where** — Keychain Access field for the service (`security add-generic-password -s`).
- **Comments / Notes** — Keychain Access Comments (`security add-generic-password -j`). ezkey **Notes**. These are item attributes, not the password.
- **login Keychain** — `~/Library/Keychains/login.keychain-db` on macOS.
- **Always Allow** — a button in the macOS Keychain password prompt. It asks macOS to stop prompting this app for that item, but macOS may still ask again. ezkey never suppresses or bypasses the prompt, so it behaves like Keychain Access.
- **Retrieve** — look up an item by name; partial names list matches without showing the secret until you pick one.
