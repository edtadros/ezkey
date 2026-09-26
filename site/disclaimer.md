---
title: Disclaimer — ezkey.app
description: As-is terms for ezkey. Present this before building or granting Keychain access.
---

# Disclaimer

ezkey is free software provided **as is**, with **no warranty** and **no support obligation**.

It is a local macOS utility. It is not a hosted password manager, not a backup service, and not a product with a vendor relationship. The author does not receive your secrets, does not operate a server for this project, and cannot recover keys you lose.

## Keychain access is your decision

macOS asks for your login password when ezkey reads a secret that another app saved. **Allow** and **Always Allow** are decisions you make. macOS can ask again next time, even after you click **Always Allow**. ezkey does not suppress or work around that prompt. That is on purpose: you get the same protection as Keychain Access, which asks every time you show a password. Secrets you save with ezkey usually open without a prompt.

Only run ezkey you built yourself. Do not grant Keychain access to forks you have not reviewed.

## Build it yourself

ezkey is open source. You **build it from source** on your own Mac, from the newest release tag on GitHub. If you want to check it first, ask your own agent to review the code. We encourage that. The [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md) includes a review checklist. A review lowers risk. It does not prove the code is safe.

## Limitation of liability

To the maximum extent permitted by law, the author is not liable for lost secrets, unauthorized access, data loss, interrupted work, or any other damages arising from use of this software, including use of **Always Allow**, use of binaries you did not build, or use of modified copies.

See [LICENSE](LICENSE) (MIT).
