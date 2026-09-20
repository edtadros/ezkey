---
title: security add-generic-password on macOS — ezkey.app
description: security add-generic-password writes a login Keychain item. Use -a, -s, prompt for -w, and the login.keychain-db path. ezkey stores the same Name/Where pair.
---

# How do I use security add-generic-password?

`security add-generic-password` writes a generic-password item, usually into the login Keychain. Required ideas: `-a` account, `-s` service (Where), `-w` password. Leave `-w` without a value so the tool prompts, or you will put the secret in shell history. ezkey.app uses the same account (your Mac user) and stores Name as both label and service.

## Flags that matter

| Flag | Meaning | ezkey |

| --- | --- | --- |

| -a | Account | Always the logged-in Mac user; hidden in the UI |

| -s | Service / Where | Same string as Name |

| -l | Label / Name | Same string as Where |

| -w | Password | The secret; prefer a prompt |

| -U | Update if present | Save refuses duplicates until you Update |

| keychain path | Which file | login.keychain-db |

## Add or update

```
security add-generic-password -U -a "$USER" -s "my-app-api-token" -w \
  "$HOME/Library/Keychains/login.keychain-db"
```

ss64 and `man security` document the rest. Creator codes and `-T` trusted apps are how Access Control lists get weird. Default trust includes the creating app. ezkey’s code signature is what Always Allow binds to later.

A common copy-paste sets `-a` to the service name and `-s` to the key name, or the reverse. Then Keychain Access looks empty when you search the string you remember. Pick a convention and keep it. ezkey’s convention is: the Name you type is both label and service; account is the Mac user. If you already have CLI items with a different account string, Retrieve will not see them until you save under the Mac user or search from Access.

## Find and print

```
security find-generic-password -a "$USER" -s "my-app-api-token" -w \
  "$HOME/Library/Keychains/login.keychain-db"
```

`-w` on find prints only the password. Without it you get attributes. macOS may show a dialog the first time a different app reads the item.

Printing to stdout is a feature and a footgun. Anything that logs the command output now has the secret. Prefer assigning to a variable, passing to the child, and unsetting. `echo $SECRET` in a shared screen session is how keys travel. ezkey’s copy button is the same class of risk for thirty seconds. That is documented, not hidden.

## How this maps to ezkey

If you save `my-app-api-token` in ezkey, Keychain Access shows that string as Name and Where. `security find-generic-password -s my-app-api-token -a "$USER" -w` should print the same secret after you allow access. That round-trip is the point. See [ezkey vs Keychain Access](/compare/ezkey-vs-keychain-access/).

## Related answers

- [How to save API keys securely on a Mac](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac/): Why the CLI should prompt for -w.
- [Glossary](https://ezkey.app/glossary/): Name, Where, Account.
- [ezkey vs Keychain Access](https://ezkey.app/compare/ezkey-vs-keychain-access/): Same file, different UI.
- [Security](https://ezkey.app/security/): Always Allow and prompts.

## What is the difference between -s and -l?

-s is service (Where). -l is label (Name). If you omit -l, label defaults to the service. ezkey sets both to the Name you type.

## Why does find fail after I saved in ezkey?

Account must match. ezkey always uses the logged-in username. Pass -a "$USER".

## Can I use -A?

No. -A allows any application to read the item without warning. That is the opposite of careful.

## Does this work over SSH?

Often you will get a prompt you cannot click. File-based Keychain access from SSH is a known pain. ezkey does not fix that.
