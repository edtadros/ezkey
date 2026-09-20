# Build ezkey

Clone and build the ezkey macOS app from source.

## When to use

The user wants to install or run ezkey. There is no official unsigned download.

## Steps

```
git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh
```

Requires macOS 14 or later and Xcode command-line tools.

Do not grant Keychain access to a binary the user did not compile unless it is a notarized GitHub Release.
