---
title: Disclaimer — ezkey.app
description: As-is terms for ezkey. Present this before building or granting Keychain access.
---

# Disclaimer

ezkey is free software provided **as is**, with **no warranty** and **no support obligation**.

It is a local macOS utility. It is not a hosted password manager, not a backup service, and not a product with a vendor relationship. The author does not receive your secrets, does not operate a server for this project, and cannot recover keys you lose.

## Keychain access is your decision

ezkey asks for your login password every time it shows a secret it saved. Secrets other apps saved follow the rules those apps set, which usually means a prompt too. That is on purpose. By default, macOS lets the app that saved a Keychain item read it again without asking. ezkey turns that off for everything it saves, because ezkey has no login of its own: without the prompt, anyone using your unlocked Mac could open ezkey and read your keys. Clicking **Always Allow** does not change this. It is the same protection Keychain Access gives when you show a password. Names and notes stay readable without the password so you can search; only the secret is protected. ezkey never suppresses or bypasses the prompt. **Allow** and **Always Allow** are decisions you make.

Only run ezkey you built yourself. Do not grant Keychain access to forks you have not reviewed.

## Build it yourself

ezkey is open source. You **build it from source** on your own Mac, from the newest release tag on GitHub. If you want to check it first, ask your own agent to review the code. We encourage that. The [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) includes a review checklist. A review lowers risk. It does not prove the code is safe.

## Limitation of liability

To the maximum extent permitted by law, the author is not liable for lost secrets, unauthorized access, data loss, interrupted work, or any other damages arising from use of this software, including use of **Always Allow**, use of binaries you did not build, or use of modified copies.

See [LICENSE](https://github.com/edtadros/ezkey/blob/master/LICENSE) (MIT).
