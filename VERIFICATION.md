# ezkey verification

Date: 2026-09-17. Host: macOS 26.6.1. Local Apple Development signing was used for this machine only. Public binaries require Developer ID + notarization.

## Keychain backend (before UI)

A probe against `~/Library/Keychains/login.keychain-db` showed that `SecItemAdd` / `SecItemCopyMatching` items are visible to:

```sh
security find-generic-password -a "$USER" -s "<service>" -w "$HOME/Library/Keychains/login.keychain-db"
```

and that `security add-generic-password` items are visible to `SecItemCopyMatching`. Naive `SecItemAdd` also landed in the login Keychain on this Mac. ezkey still opens that file with `SecKeychainOpen`, `kSecUseKeychain`, and `kSecMatchSearchList`, and sets `kSecUseDataProtectionKeychain` to false, so it does not use the data-protection / app-only store.

The probe used disposable `ezkey.test.probe.*` entries and cleaned them up. It did not modify unrelated login Keychain items.

## Automated tests

`swift test`: 29 tests, 0 failures.

- Models: identity trimming, error mapping, disposable prefix vs unrelated services
- PanelModel: save, explicit update, missing/cancelled/denied, mask/reveal, copy, panel-close clearing, in-flight retrieve discard, label persistence
- ClipboardGuard: 30-second clear only if the pasteboard still holds ezkey's value
- LoginKeychainStore (same-process, `allowsPrompt: false`): add/retrieve, update without clobbering another pair, missing entry, Unicode/spaces/quotes round trip, duplicate add

Unsigned `xctest` cannot read another app's login-Keychain secret without the login password prompt, so XCTest does not call `security -w`. CLI interop is in the signed-app self-test.

## Signed app self-test

`build/ezkey.app/Contents/MacOS/ezkey --self-test` (Apple Development signed):

- PASS same-process-roundtrip (spaces, quotes, café, 🔑)
- PASS comment-roundtrip
- PASS contains-without-returning-secret
- PASS app-add-visible-to-security-cli (attribute lookup in `login.keychain-db`)
- PASS comment-visible-to-security-cli
- PASS cli-add-visible-to-app
- PASS cli-comment-visible-to-app
- PASS update-does-not-clobber-other-pair
- PASS missing-entry

Cleanup only deleted `ezkey.test.*` items created by the test.

## Live app

- `build/ezkey.app` launched; process `ezkey` is `background only` (no Dock icon). `LSUIElement` is true.
- Menu-bar extra: a key icon appears after launch (confirmed by before/after screenshots of the menu bar). Calling `NSApp.setActivationPolicy(.accessory)` after SwiftUI builds `MenuBarExtra` removed the extra on this OS; the app relies on `LSUIElement` instead.
- Assistive access is not granted to this agent, so the panel was not clicked end-to-end. Save/Retrieve/Update/Reveal/Hide/Copy/Quit behavior is covered by PanelModel tests against the same views' model.

## Spec items

| Item | Result |
| --- | --- |
| Terminal create, ezkey retrieve | Self-test `cli-add-visible-to-app`; secret `-w` retrieve prompts (expected) |
| ezkey create, terminal retrieve | Self-test `app-add-visible-to-security-cli`; probe also did `-w` after Allow |
| Update one pair, leave another | PASS in XCTest and self-test |
| Missing entry | PASS |
| Cancelled / access denied | PASS in PanelModel tests; live dialogs need a person to Allow/Deny/Cancel |
| Mask, reveal/hide, copy, conditional clipboard clear | PASS in PanelModel and ClipboardGuard tests |
| Spaces, quotes, Unicode | PASS |
| Close panel clears secrets | PASS (`panelDidClose`) |
| Existing credentials | Untouched; tests refuse to mutate non-`ezkey.test.` services |

## Remaining limitations

- File-based Keychain APIs (`SecKeychainOpen`, `SecAccessCreate`, trusted applications) are deprecated. They are the APIs that target `login.keychain-db`.
- `security find-generic-password -w` on an item created by another process shows a Keychain prompt. That is normal. Attribute lookup does not.
- The first Allow/Deny/Cancel on a given item is not automatable here without the login-Keychain password or assistive access.
- Menu-bar extras on this machine sit left of the usual Control Center cluster (around the notch). A right-side crop will miss the key icon.
