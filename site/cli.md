---
title: CLI — ezkey.app
description: ezkey is a menu bar app built from source. Install it with your agent.
---

# ezkey CLI

ezkey is a menu bar app, not a command-line tool. You build it from source on your Mac.

## Install

Ask your agent to follow the [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md). It shows you the disclaimer, clones the newest `v*` release tag, reviews the code, and shows you the results. It runs `./scripts/install.sh` only after you say go. That copies the app to `/Applications/ezkey.app` and turns on Open at Login.

By hand:

```
git clone --depth 1 --branch <tag> https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh
```

Replace `<tag>` with the newest `v*` release tag.

## Public API equivalent

```
curl -sS https://ezkey.app/api/v1/agent-brief
curl -sS https://ezkey.app/api/v1/cli
```

No API key. `/api/v1/cli` stays for compatibility. It returns `"cli": null` and points to the skill. You build the app from source on your Mac. Only run ezkey you built yourself.
