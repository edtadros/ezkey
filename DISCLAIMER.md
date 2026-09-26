# Disclaimer

ezkey is free software provided **as is**, with **no warranty** and **no support obligation**.

It is a local macOS utility. It is not a hosted password manager, not a backup service, and not a product with a vendor relationship. The author does not receive your secrets, does not operate a server for this project, and cannot recover keys you lose.

## Keychain access is your decision

macOS will ask before ezkey can read a Keychain item created by another program. **Allow** and **Always Allow** are decisions you make.

ezkey never suppresses or bypasses these prompts. macOS can ask again even after **Always Allow**, the same as Keychain Access.

Only grant Keychain access to ezkey you built yourself, from source you or your agent reviewed.

## Build it yourself

You get ezkey by **building it from a release tag of the source on GitHub**. Reviewing the code first, yourself or with your agent, is encouraged. A review lowers risk. It does not prove the code is safe.

## Limitation of liability

To the maximum extent permitted by law, the author is not liable for lost secrets, unauthorized access, data loss, interrupted work, or any other damages arising from use of this software, including use of **Always Allow**, use of builds you did not make yourself, or use of modified copies.

See [LICENSE](LICENSE) (MIT).
