---
title: Store API keys locally on a Mac — ezkey.app
description: If an API key must not leave this Mac, put it in the login Keychain, not in a cloud password manager and not in a project .env. ezkey is a local extra for those items.
---

# Where should local API keys live on a Mac?

If the rule is that the key must not leave this computer, the login Keychain is the local store that macOS already encrypts. Do not use iCloud-synced password apps as the canonical copy for that key. Do not use `.env`. ezkey.app writes generic passwords into login.keychain-db and nowhere else.

## The local-only rule

Some keys are more like house keys than like shared office badges. A personal OpenAI key that bills your card. A staging token for an app that is not supposed to exist yet. A webhook secret on a machine that never opens a ticket with a vendor. Those keys should not ride a sync channel you cannot see.

Cloud password managers are good at the opposite job. They are designed to leave this Mac. If you put a “never leave” key there, you have redefined the job.

Local-only is not the same as “I turned off Wi-Fi.” iCloud Drive can still ship a `.env` to another device. Screenshots still leave. The rule is: the canonical bits sit in login.keychain-db, the login password is the recovery, and no vendor account is in the path. If that recovery story scares you, you do not want a local-only key. You want a vault with a recovery mailbox. Say that out loud before you mix the two.

## Why iCloud Keychain is the wrong drawer

iCloud Keychain / Passwords is built to appear on your phone. Generic passwords in login.keychain-db do not automatically do that. ezkey uses the file-based login Keychain so `security` and Keychain Access see the same items. That is a compatibility choice and a locality choice. Read [how to save API keys securely](/guides/how-to-save-api-keys-securely-on-mac/) if you need the mechanics.

Developers sometimes hear “use the Secure Enclave” and assume every Keychain item is hardware-bound. Generic passwords in the login file are not Secure Enclave keys. They are encrypted items in a file. FileVault protects the disk when the Mac is off. The login password protects the Keychain file. Touch ID on a different item class is a different product. ezkey does not pretend otherwise.

## Practice

1. Name the key as if you will search for it in six months.
2. Save it with ezkey or security(1) into login.keychain-db.
3. Export into the environment only in the terminal that runs the client.
4. Delete `.env` copies and zshrc exports of the raw value.
5. Rotate anything that already escaped.

Build ezkey from [source](https://github.com/edtadros/ezkey) if the menu bar extra is useful. If it is not, the Keychain is still the right drawer.

A local-only key still dies with the disk if you have no backup of login.keychain-db and you forget the login password. That is the trade. Encrypted backup of the Keychain file is your problem, not ezkey’s. Do not email yourself the secret as a “backup.” That email is a second canonical copy in a worse store.

## Related answers

- [Best way to store API keys on macOS](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos/): Local vs team split.
- [Keychain vs 1Password](https://ezkey.app/compare/macos-keychain-vs-1password-for-api-keys/): Honesty section included.
- [For developers](https://ezkey.app/for/developers/): CLI compatibility.
- [Privacy](https://ezkey.app/privacy/): The app collects nothing.

## Can I back up login.keychain-db?

Time Machine will copy the encrypted file. That is a backup of ciphertext plus your login password story. Treat the login password as the recovery.

## What if I need the key on two Macs?

Then it is not a local-only key. Use a vault with a sharing model you accept, or carry it yourself.

## Does ezkey phone home?

The app has no network calls. This website is static docs. Do not paste secrets into GitHub issues.

## Is FileVault required?

It is the disk-at-rest control. Use it. ezkey will still run without it; the threat model gets worse.
