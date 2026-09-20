---
title: Is it safe to put API keys in .env files? — ezkey.app
description: A .env file is plaintext. It is fine for non-secrets. It is a common way API keys leak through git, zips, and backups. Use the login Keychain as the canonical store on a Mac.
---

# Is it safe to put API keys in .env files?

No, not as the canonical store. A `.env` file is plaintext on disk. `.gitignore` only helps if everyone remembers it, including the zip you upload and the colleague’s backup. On a Mac, keep the live key in the login Keychain and, if a tool insists on an environment variable, export it for one process.

## Why dotenv became the default

Twelve-factor config said “store config in the environment.” Frameworks translated that into a file named `.env` that the process reads at boot. That is convenient. It is also a file. Files get copied. The pattern spread because it is easy to document: put `DATABASE_URL=` here. Safety was someone else’s `.gitignore`.

## How .env files actually leak

- git add -f, or a first commit before gitignore existed.
- A zip of the project mailed to a contractor.
- iCloud Drive or Dropbox sync of the repo folder.
- A screenshot or a screen share that includes the editor tab.
- CI caches and Docker layers that ingested the file as a build context.

None of those require a sophisticated attacker. They require a tired Thursday. Once a live key is in git history, rotating the key is the fix, not another gitignore line.

Dotenv files also train muscle memory in the wrong direction. You open a new repo, copy `.env.example` to `.env`, paste live values, and get to work. Six months later the example file has a real key because someone “just needed it to run.” Code review does not catch a file gitignore hides. The Keychain does not sit next to `src/`.

## Why gitignore is not a control

`.gitignore` is a filter for one tool. It does not encrypt. It does not stop `cp`. It does not stop Time Machine. It does not stop an editor plugin that uploads the workspace. Treat gitignore as politeness toward your future self, not as access control.

## What to do instead on macOS

Keep the canonical secret in the login Keychain. See [how to save API keys securely on a Mac](/guides/how-to-save-api-keys-securely-on-mac/). If a local server must see `OPENAI_API_KEY`, export it in that terminal from `security find-generic-password` or retrieve it in ezkey and paste once into a process you will kill. Do not recreate a long-lived `.env` that is just the Keychain dumped to disk.

For a walkthrough with the OpenAI variable name, see [how to store an OpenAI API key on a Mac](/guides/how-to-store-openai-api-key-on-mac/).

## Related answers

- [How to save API keys securely on a Mac](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac/): Keychain first, leftovers deleted.
- [Best way to store API keys on macOS](https://ezkey.app/guides/best-way-to-store-api-keys-on-macos/): The comparison table.
- [For developers](https://ezkey.app/for/developers/): Local Keychain items, source you can read.
- [Glossary](https://ezkey.app/glossary/): Name, Where, Account.

## What if the framework requires a .env?

Give it a file that points at non-secrets, or generate a throwaway env in memory. Do not let the committed example contain a real key.

## Are encrypted .env tools enough?

They are better than plaintext. You then have a new format, a passphrase, and another binary. The login Keychain is already on the Mac.

## Does Docker make this worse?

Yes if you COPY a .env into an image or pass secrets as build args that land in layers. Use runtime secrets, not files in the context.

## Can ezkey write a .env for me?

No. ezkey does not write project files. It talks to the Keychain only.
