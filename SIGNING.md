# Maintainer signing setup

The default build and CI use ad hoc signing. Signing setup does not change where keys are stored. The app and `--self-test` still use the file-based login Keychain.

`Resources/ezkey.entitlements` defines the signing identifiers. The build derives its bundle ID from the application identifier and Team ID there. The shared access group is `W3N4GBR8TB.app.ezkey`. A future iOS target on the same team can use this group. No sandbox or iCloud container entitlement is included.

## Environment variables

| Variable | Behavior |
| --- | --- |
| `EZKEY_SIGN_IDENTITY` | Unset, empty, or `-`: ad hoc signing without entitlements, a profile, or hardened runtime. Otherwise: sign with this identity, hardened runtime, and a secure timestamp. |
| `EZKEY_ENTITLEMENTS` | Defaults to `Resources/ezkey.entitlements`. Set a file path to override it, or `none` for a plain local identity sign without entitlements. Ignored for ad hoc signing. |
| `EZKEY_PROFILE` | Path to a provisioning profile kept outside the repo. For identity signing, the file must exist and is copied to `Contents/embedded.provisionprofile` before signing. Ignored for ad hoc signing. |
| `EZKEY_NOTARY_PROFILE` | Optional `notarytool` keychain profile name. Submits the build, waits, staples it, and verifies it before install. Ad hoc builds are refused. |

Relative file paths resolve from the repo root. Every signature is verified with `codesign --verify --deep --strict`. With notarization enabled, installation copies the stapled app without signing it again. Otherwise, both the build and installed copy use the same signing function.

`SKIP_TESTS`, `SKIP_VERIFY`, `SKIP_INSTALL`, `SKIP_LAUNCH`, and `EZKEY_INSTALL_DIR` keep their existing behavior. `SKIP_VERIFY=1` skips only the Keychain self-test, not signature verification.

## One-time Apple setup

1. Sign in to the Apple Developer account. Select the individual team and confirm Team ID `W3N4GBR8TB` under Membership details.
2. Open Certificates, Identifiers & Profiles > Identifiers > **+** > App IDs > App. Register an explicit Bundle ID, `app.ezkey`. No extra capability is needed for a plain team-prefixed keychain access group on macOS. If the portal shows Keychain Sharing, it is not required for this group.
3. Create a **Developer ID Application** certificate. In Keychain Access, choose Certificate Assistant > Request a Certificate From a Certificate Authority and save the CSR to disk. In the portal, open Certificates > **+** > Developer ID Application, upload the CSR, then download and open the certificate to install it. Alternatively, use Xcode > Settings > Accounts > select the team > Manage Certificates > **+** > Developer ID Application.
4. In the portal, open Profiles > **+** > Distribution > Developer ID. Select `app.ezkey` and the Developer ID Application certificate, name the profile, and generate it. Download the provisioning profile to a private folder outside this repo. Restricted `keychain-access-groups` need that embedded profile for Developer ID signing. Without it, AMFI kills the app at launch; the script warns when entitlements are enabled without a profile.
5. Create an app-specific password at `account.apple.com` > Sign-In and Security > App-Specific Passwords, or create an App Store Connect API key under Users and Access > Integrations. Keep credentials and API key files outside the repo. Store them locally with `xcrun notarytool store-credentials <profile-name>` and follow its prompts. Use `xcrun notarytool store-credentials --help` for the API-key options. Only the saved profile name goes in `EZKEY_NOTARY_PROFILE`.

Keep certificates, private keys, profiles, and credentials out of git. CI needs none of them.

## Build and check

Replace the certificate name and profile path with the local values. This builds and notarizes without installing or running the Keychain self-test.

```sh
EZKEY_SIGN_IDENTITY="Developer ID Application: <certificate name> (W3N4GBR8TB)" \
EZKEY_PROFILE="$HOME/Library/Developer/Signing/ezkey.provisionprofile" \
EZKEY_NOTARY_PROFILE="ezkey-notary" \
SKIP_VERIFY=1 SKIP_INSTALL=1 ./scripts/build-and-run.sh

codesign -dv --entitlements - build/ezkey.app
codesign --verify --deep --strict build/ezkey.app
spctl -a -vv build/ezkey.app
xcrun stapler validate build/ezkey.app
```

For a local identity without entitlements, set `EZKEY_SIGN_IDENTITY="<local identity>" EZKEY_ENTITLEMENTS=none` and leave `EZKEY_PROFILE` and `EZKEY_NOTARY_PROFILE` unset. This still requests hardened runtime and a secure timestamp.

Run `python3 Tests/scripts/test_signing.py` for offline packaging checks. The tests replace signing and Apple tools with local doubles and check the copied files and command order.

Moving from ad hoc signing to Team ID signing changes the app's code identity. Existing "trust ezkey" login Keychain items may prompt once to trust the new identity. Ask-every-time items are unaffected.
