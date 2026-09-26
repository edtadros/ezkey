---
title: How to save API keys securely on a Mac — ezkey.app
description: Put the canonical copy in the macOS login Keychain as a generic password. Skip .env, .zshrc, and git. Menu bar or security CLI.
---

# How can I save API keys securely on a Mac?

Store the only copy that matters in the login Keychain as a generic password. Do not leave the live value in a project `.env`, in `~/.zshrc`, or in git. On a Mac that already has FileVault and a short screen lock, the Keychain is the store Apple already runs for this job. ezkey.app is a menu bar extra for those same items. The `security` CLI talks to the same file.

## What not to do

The usual leak is not a nation-state. It is a file you forgot. A `.env` in a project directory is readable by any process running as you. If that directory is in iCloud Drive, Time Machine, or a zip you mailed, the key travels with it. `echo export OPENAI_API_KEY=sk-... >> ~/.zshrc` writes the same class of file into your home folder. OpenAI’s own setup docs still show that pattern. It keeps the key out of the git repo. It does not keep the key off disk.

Putting the value after `security add-generic-password -w` on one line is worse in a different way: the secret lands in shell history. Paste from the clipboard (`-w "$(pbpaste)"`) or omit `-w`’s argument so `security` prompts.

## What the login Keychain actually is

macOS keeps more than one keychain. The one developers mean for local generic passwords is the login Keychain, a file at `~/Library/Keychains/login.keychain-db`. It is encrypted with the login password. It unlocks when you log in. Apple’s Keychain Access app shows those items. The `security` tool reads and writes them. ezkey uses Security.framework against that same file, with Name stored as both label and service so Keychain Access Name and Where match.

That is not the Data Protection keychain, and it is not iCloud Passwords. Those are different databases. A blog that says “the Keychain is the Secure Enclave” is describing a different item class. Generic passwords in login.keychain-db are file-based. FileVault still matters: if the Mac is off or locked at the FileVault prompt, the disk is ciphertext. After you log in, the login Keychain is available to your session. Screen lock is the control for someone at the desk.

| Place | Encrypted at rest | Shows up in git | Unlocked with |

| --- | --- | --- | --- |

| .env in the repo | No | Yes, if you commit it | Anyone who can read the file |

| ~/.zshrc export | No | Only if you commit dotfiles | Anyone who can read your home |

| login Keychain generic password | Yes, login password | No | Your Mac session / Keychain ACL |

| 1Password / hosted vault | Yes, vendor model | No | Account, often with sync |

## Save from the menu bar

Build [ezkey](https://ezkey.app/) from source, click the key in the menu bar, choose Save, type a Name such as `my-app-api-token`, paste the secret, save. Account is the logged-in Mac user and stays hidden. Retrieve can take a substring of the name and list matches without showing secrets until you pick one. Copy clears in 30 seconds if the pasteboard still holds what ezkey put there.

![ezkey Save panel](https://ezkey.app/images/panel-save.png)

![ezkey Retrieve with matching names](https://ezkey.app/images/panel-matches.png)

There is no prebuilt app. Clone the newest release tag of https://github.com/edtadros/ezkey and run `./scripts/install.sh`. That copies `ezkey.app` to `/Applications` and turns on Open at Login. To have your agent review the code first, use the [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md). Do not grant Keychain access to a random `.app`.

## Save from Terminal without shell history

```
security add-generic-password -U -a "$USER" -s "my-app-api-token" -w "$HOME/Library/Keychains/login.keychain-db"
# omit the password after -w so security prompts
# or: -w "$(pbpaste)"
```

`-s` is the service, which Keychain Access shows as Where. ezkey stores the same string as Name (label) and Where (service). `-a "$USER"` is the account ezkey always uses. `-U` updates if the pair already exists. Point at login.keychain-db if you do not want the default keychain to surprise you.

## Use the key without leaving it on disk

```
export MY_APP_API_TOKEN="$(security find-generic-password -a "$USER" -s "my-app-api-token" -w "$HOME/Library/Keychains/login.keychain-db")"
# run the tool
unset MY_APP_API_TOKEN
```

That export lives in the process environment for that shell. Other processes running as you can still read it while it is set. It is still better than a file that lasts for years in a backup. Do not put the `export` of the raw key into zshrc. Putting the `security find-generic-password` substitution in zshrc will prompt or fail in non-interactive sessions; that is a trade, not a bug.

## What this does not protect you from

- Malware already running as you, after the Keychain is unlocked.
- A secret you paste into Slack, an issue tracker, or a screenshot.
- A binary you Always Allow that you did not compile.
- Need to share the same key with a team. That is a vault product, not login.keychain-db.

ezkey does not claim otherwise. It is MIT, as-is, no warranty. Read the [security](/security/) notes on Always Allow and the [glossary](/glossary/) for Name, Account, and Where.

## Related answers

- [Best way to store API keys on macOS](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos/): How the options compare when you already have a Mac.
- [Is it safe to put API keys in .env files?](https://ezkey.app/guides/is-it-safe-to-put-api-keys-in-dotenv/): When a dotenv file is a leak waiting for a zip.
- [security add-generic-password](https://ezkey.app/guides/security-add-generic-password/): The CLI the menu extra is compatible with.
- [ezkey for developers](https://ezkey.app/for/developers/): Local keys, no account, source you can read.

## Is the login Keychain the same as iCloud Keychain?

No. Generic passwords ezkey writes go in ~/Library/Keychains/login.keychain-db. That file is local. iCloud Keychain is a different store and is not what ezkey uses.

## Should I put the key in ~/.zshrc after I save it?

No. Export it for the session you need: export MY_KEY="$(security find-generic-password -s NAME -a "$USER" -w)". A line in zshrc with the raw key is a plaintext file again.

## Does ezkey sync keys to other Macs?

No. There is no account and no server. Copying a Keychain to another machine is a macOS problem, not an ezkey feature.

## Is Always Allow safe?

Always Allow is a standing grant to the code signature of the build you compiled. Each rebuild changes that signature, so macOS may ask again after an update. Do not give it to a downloaded .app.
