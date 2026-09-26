# Disclaimer

ezkey is free software provided **as is**, with **no warranty** and **no support obligation**.

It is a local macOS utility. It is not a hosted password manager, not a backup service, and not a product with a vendor relationship. The author does not receive your secrets, does not operate a server for this project, and cannot recover keys you lose.

## Keychain access is your decision

macOS will ask before ezkey can read a Keychain item created by another program. **Allow** and **Always Allow** are decisions you make.

**Always Allow** attaches to the code signature of the build you compiled. Each rebuild changes it, so macOS may ask again after an update. Grant it only if you intend to trust this program.

Do not grant Keychain access to unofficial builds, random `.app` files from the web, or forks you have not reviewed.

## No official binary

The only supported way to obtain ezkey is to **build it from a release tag of the source on GitHub**. There is no prebuilt app. Treat any downloadable `.app` or `.dmg` as unofficial. An agent's code review before building lowers risk. It does not prove the code is safe.

## Limitation of liability

To the maximum extent permitted by law, the author is not liable for lost secrets, unauthorized access, data loss, interrupted work, or any other damages arising from use of this software, including use of **Always Allow**, use of unofficial binaries, or use of modified copies.

See [LICENSE](LICENSE) (MIT).
