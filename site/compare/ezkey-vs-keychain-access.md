---
title: ezkey vs Keychain Access — ezkey.app
description: Both use the macOS login Keychain. Keychain Access is the system UI. ezkey is a menu bar extra for generic passwords with substring retrieve. Same file, different job.
---

# ezkey vs Keychain Access

Keychain Access is Apple’s app for every kind of Keychain item. ezkey.app is a tiny extra for generic passwords: save, retrieve by name or substring, reveal, copy. They can see the same login.keychain-db items when Name/Where and Account match. Use Access for certificates and ACLs. Use ezkey if you live on one Name field in the menu bar.

## Same database

ezkey opens `~/Library/Keychains/login.keychain-db` through Security.framework. Keychain Access shows that file as the login keychain. If you save `my-app-api-token` in ezkey, Access should list it with Name and Where set to that string and Account set to your user. The [glossary](/glossary/) is the field map.

## Different job

|  | Keychain Access | ezkey |

| --- | --- | --- |

| Scope | Passwords, keys, certs, notes | Generic passwords only |

| Find | Search box, lots of columns | Exact Name, then substring list |

| Always in the menu bar | No | Yes |

| Clipboard timer | No | 30 seconds if unchanged |

| ACL editor | Yes | No |

| Source | Closed, from Apple | MIT, github.com/edtadros/ezkey |

## When Keychain Access is better

Certificates, code signing identities, looking at Access Control, fixing a stuck Always Allow, inspecting iCloud items. ezkey will not grow into that. If you need those tools, open Access. That is not a failure of ezkey. It is the division of labor.

Access is also the right place when an item will not delete, when two items share a confusing Where, or when you need to see which apps are trusted. ezkey will not show ACL entries. If Retrieve fails with a prompt you do not understand, open Access, find the item, and read Access Control. Then decide whether Always Allow is something you want to give a binary you compiled.

## When ezkey is better

You save and retrieve a handful of API tokens every week. You know the Name. You do not want to hunt Kind columns. You want a masked field and a copy button. You want `security` to keep working. Then a menu extra that only does generic passwords is calmer than Access. Build it yourself. See [for developers](/for/developers/).

ezkey will not import a CSV of passwords. It will not show your Safari logins. If Access is open because you are hunting a Wi-Fi password, stay there. If Access is open because you cannot remember the `-s` string for a generic password you created last month, the extra’s substring list is the feature.

## Related answers

- [security add-generic-password](https://ezkey.app/guides/security-add-generic-password/): The CLI both of you sit on.
- [Save API keys securely](https://ezkey.app/guides/how-to-save-api-keys-securely-on-mac/): The actual procedure.
- [Keychain vs 1Password](https://ezkey.app/compare/macos-keychain-vs-1password-for-api-keys/): Different layer.
- [Security](https://ezkey.app/security/): Prompts and Always Allow.

## Will an item I create in Access show up in ezkey?

If it is a generic password, account is your Mac user, and you search the Name/Where string, yes. Other item classes will not.

## Can ezkey edit Access Control lists?

No. Use Keychain Access.

## Does ezkey replace security(1)?

No. It is compatible with add/find-generic-password for the fields it uses.

## Why isn’t ezkey sandboxed?

A sandbox would store items where the security CLI cannot see them. Compatibility with CLI items is the point.
