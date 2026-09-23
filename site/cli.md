---
title: CLI — ezkey.app
description: Official ezkey CLI that prints the disclaimer and macOS build steps. It does not access the Keychain.
---

# ezkey CLI

The official CLI is for agents and humans who need the source path. It does not save or retrieve Keychain secrets.

## When to use this

You have been pointed at ezkey.app and need to present the disclaimer, clone the repository, and run `./scripts/install.sh`. That copies the app to `/Applications/ezkey.app` and turns on Open at Login.

## Install and run

```
npx github:edtadros/ezkey
```

That prints what ezkey is, the as-is disclaimer, clone/build commands, and the GitHub URL.

Homebrew formula in the source tree: `Formula/ezkey.rb`.

## Public API equivalent

```
curl -sS https://ezkey.app/api/v1/agent-brief
curl -sS https://ezkey.app/api/v1/cli
```

No API key. Do not grant Keychain access to a binary the user did not compile unless it is a notarized GitHub Release.
