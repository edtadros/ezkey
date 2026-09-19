# Disclaimer

ezkey is free software provided **as is**, with **no warranty** and **no support obligation**.

It is a local macOS utility. It is not a hosted password manager, not a backup service, and not a product with a vendor relationship. The author does not receive your secrets, does not operate a server for this project, and cannot recover keys you lose.

## Keychain access is your decision

macOS will ask before ezkey can read a Keychain item created by another program. **Allow** and **Always Allow** are decisions you make.

**Always Allow** attaches to ezkey's code signature. Later copies of ezkey signed with the same Developer ID may be able to read those items without another prompt. Grant that only if you intend to trust this program, including future versions you install from a channel you have verified.

Do not grant Keychain access to unofficial builds, random `.app` files from the web, or forks you have not reviewed.

## No official unsigned binary

The supported way to obtain ezkey is to **build it from the source on GitHub**. A prebuilt app is official only if it is a GitHub Release that Apple has notarized. Until such a release exists, treat any downloadable `.app` or `.dmg` as unofficial.

## Limitation of liability

To the maximum extent permitted by law, the author is not liable for lost secrets, unauthorized access, data loss, interrupted work, or any other damages arising from use of this software, including use of **Always Allow**, use of unofficial binaries, or use of modified copies.

See [LICENSE](LICENSE) (MIT).
