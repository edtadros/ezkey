---
title: How to store an OpenAI API key on a Mac — ezkey.app
description: Do not put OPENAI_API_KEY in ~/.zshrc. Save it as a login Keychain generic password, then export it for one shell. ezkey and security(1) use the same item.
---

# How do I store an OpenAI API key on a Mac?

Do not follow the “append export OPENAI_API_KEY to ~/.zshrc” snippet as the canonical store. Save the key as a generic password in the login Keychain under a Name you choose, then export it into the environment for the shell that talks to the API. ezkey.app and `security` write the same kind of item.

## What OpenAI’s docs tell you

OpenAI’s API key safety page tells macOS users to append `export OPENAI_API_KEY='yourkey'` to `~/.zshrc`. That keeps the key out of the git repository. It still writes a plaintext secret into a dotfile that backup software loves. Plenty of leaked keys started as that one line. Use the dashboard to create the key. Do not use zshrc as the vault.

The same advice shows up for Anthropic, Gemini, and Stripe: put the token in the environment. The environment is a good *delivery* path for one process. It is a bad *archive*. Once `OPENAI_API_KEY` is in zshrc, every plugin, every `source`, every `bash -lc` from an editor can inherit it. That is convenient for demos and noisy for threat models. Keep the archive in the Keychain. Deliver to the environment on purpose.

## Save the key

In ezkey: Save, Name `openai-api-key`, paste the secret. In Terminal, omit the password on `-w` so it does not hit history:

```
security add-generic-password -U -a "$USER" -s "openai-api-key" -w "$HOME/Library/Keychains/login.keychain-db"
```

Same file Keychain Access lists under login. Same pair ezkey retrieves. See [security add-generic-password](/guides/security-add-generic-password/) for flags.

## Export for one session

```
export OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s "openai-api-key" -w "$HOME/Library/Keychains/login.keychain-db")"
# python / node / curl that reads OPENAI_API_KEY
unset OPENAI_API_KEY
```

SDKs that call `os.environ["OPENAI_API_KEY"]` work unchanged. You did not invent a new config format. You stopped storing the live value in a file next to your shell config.

## If it already leaked

Revoke the key in the OpenAI dashboard first. Then save the new one in the Keychain. Then hunt `.env`, zshrc, GitHub gists, and CI variables. A Keychain item does not un-leak a key that already hit a public repo.

## Related answers

- [How to save API keys securely on a Mac](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac/): The general rule, not just OpenAI.
- [Are .env files safe?](https://ezkey.app/guides/is-it-safe-to-put-api-keys-in-dotenv/): Why gitignore is not encryption.
- [For local API keys](https://ezkey.app/for/local-api-keys/): When the token must not leave this Mac.
- [For developers](https://ezkey.app/for/developers/): Build ezkey and read the Keychain calls.

## Can I name the Keychain item OPENAI_API_KEY?

Yes. ezkey will show that as Name. The environment variable name is independent; you export whatever the SDK reads.

## Does ChatGPT Desktop use this item?

No. That app has its own sign-in. This is for API keys your local scripts and CLIs use.

## Will this sync to my iPhone?

Not through ezkey. login.keychain-db is local. iCloud Keychain is a different store.

## Is this official OpenAI software?

No. ezkey is independent MIT software. OpenAI is a trademark of its owner.
