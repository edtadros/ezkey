---
name: build-ezkey
description: Clone and build the ezkey macOS menu bar app from source. Use when the user wants to install or run ezkey. There is no official unsigned download.
---

# Build ezkey

Clone and build the ezkey macOS app from source.

## When to use

The user wants to install or run ezkey on a Mac. There is no official unsigned download. Do not fetch a random `.app` from the internet.

## Steps

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh
```

Requires macOS 14 or later and Xcode command-line tools.

Do not grant Keychain access to a binary the user did not compile unless it is a notarized GitHub Release.

## References

- Source: https://github.com/edtadros/ezkey
- Site: https://ezkey.app/
- Developers: https://ezkey.app/developers/
- Security: https://ezkey.app/security.md
