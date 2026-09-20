---
title: Best way to store API keys on macOS — ezkey.app
description: For a solo Mac, the best local store for API keys is the login Keychain. Compare .env, zshrc, security CLI, ezkey, and 1Password without pretending one tool wins every job.
---

# What is the best way to store API keys on macOS?

For a single Mac you control, the best place for the canonical API key is a generic password in the login Keychain. Use Keychain Access, `security`, or ezkey.app to write it. Use 1Password or a team vault when you must share, audit, or recover across people. Do not treat `.env` or `~/.zshrc` as the canonical copy.

## Name the job before the tool

“Best” is not a brand. It is a match between the threat and the workflow. A Stripe live key on a laptop that also has your personal photos is a different job than a staging token on a CI runner. People ask for the best way to save keys when they have just pasted `sk-live` into a `.env` and felt sick. That job is: one human, one Mac, keys that must not hit GitHub.

If the job is “the intern in another city needs the same key Monday,” stop. That is a shared vault, a platform secret manager, or a short-lived token. The login Keychain will not email it to them, and ezkey will not either.

## Options compared

| Method | Canonical copy lives | Good for | Bad for |

| --- | --- | --- | --- |

| .env in the project | Disk, often next to code | Non-secret config | Anything that spends money if leaked |

| export in ~/.zshrc | Dotfile on disk | Non-secret PATH tweaks | API keys; they sit in backups forever |

| security CLI | login Keychain | Scriptable local secrets | Daily retrieve if you hate flags |

| Keychain Access | login Keychain | Seeing what is already there | Fast save/retrieve of one generic password |

| ezkey menu extra | Same login Keychain | Named items you already keep locally | Teams, iOS, recovery after you forget the password |

| 1Password / Bitwarden | Vendor vault, usually synced | People, sharing, travel | Air-gapped local-only policy |

## Best default for one Mac

Turn FileVault on. Require a password when the screen sleeps. Put the key in the login Keychain. Pull it into the environment only for the command that needs it. Delete the plaintext leftovers. That stack uses software Apple already ships. You can inspect the item in Keychain Access. You can round-trip with `security find-generic-password`. You can use [ezkey](https://ezkey.app/) if you want the same item without memorizing `-s` and `-a`.

PassStore, NoxKey, and similar apps add their own vault format, Touch ID theater, or MCP tools. Some of them still wrap Keychain. Some invent a second encrypted file. A second format is another thing to back up and another binary to trust. For a handful of generic passwords, the login Keychain is enough.

## When a hosted vault wins

1Password, Bitwarden, and company secret managers win when you need: another person to get the value; a phone in the same account; a recovery story that is not “I hope Time Machine ran”; an audit log. They lose when your rule is “this token never leaves the building” or “I will not create an account for a local file.” See [macOS Keychain vs 1Password for API keys](/compare/macos-keychain-vs-1password-for-api-keys/).

## Where ezkey fits

ezkey is not trying to be the best password manager. It is a menu bar extra for generic passwords in login.keychain-db. Build it from source. It is MIT, as-is. If that is more trust than you want, use Keychain Access and `security` alone. They already work. The extra exists because retrieve-by-substring and a masked field are faster than clicking through Access Control lists when you do this every day.

## Related answers

- [How to save API keys securely on a Mac](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac/): The step-by-step, including the CLI prompt trick.
- [Keychain vs 1Password](https://ezkey.app/compare/macos-keychain-vs-1password-for-api-keys/): Honest split: local vs shared.
- [For local API keys](https://ezkey.app/for/local-api-keys/): When the key should never leave this Mac.
- [Store an OpenAI API key on a Mac](https://ezkey.app/guides/how-to-store-openai-api-key-on-mac/): The same rule, with OPENAI_API_KEY as the example.

## Is 1Password better than the Keychain?

For family passwords, sharing, and travel recovery, usually yes. For a local API token that should never leave this Mac, the login Keychain avoids an account and a sync channel.

## Is envchain or direnv enough?

They are loaders. If they still keep a plaintext file, you have not moved the canonical copy. If they wrap Keychain, they are in the same family as security(1).

## Should I use the Data Protection keychain instead?

Only if your app is written for it. launchd helpers and the classic `security` CLI speak the file-based login Keychain. ezkey targets that file on purpose so CLI items round-trip.

## What is the best Name for a key?

A stable handle you will type later, such as my-app-api-token. ezkey uses that string as Keychain Access Name and Where.
