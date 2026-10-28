"""Run the packaging script with local tool doubles; no credentials or network."""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
TOOL = r'''
import json
import os
from pathlib import Path
import shutil
import sys

command = Path(sys.argv[0]).name
args = sys.argv[1:]
event = {"command": command, "args": args}
if command == "codesign" and args[0] == "--force":
    contents = Path(args[-1]) / "Contents"
    profile = contents / "embedded.provisionprofile"
    event["profile"] = profile.read_text() if profile.exists() else None
    if (contents / "test-ticket").exists():
        sys.exit("refusing to re-sign a stapled fixture")
with open(os.environ["SIGNING_TEST_LOG"], "a") as log:
    log.write(json.dumps(event) + "\n")
if os.environ.get("SIGNING_TEST_FAIL") == " ".join([command] + args[:2]):
    sys.exit(42)
if command == "swift" and args[0] == "build":
    binary = Path(".build/release/ezkey")
    binary.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(sys.argv[0], binary)
    binary.chmod(0o755)
elif command == "codesign":
    signature = Path(args[-1]) / "Contents/test-signature"
    if args[0] == "--force":
        signature.write_text("fixture signature")
    elif signature.read_text() != "fixture signature":
        sys.exit(1)
elif command == "xcrun" and args[:2] == ["stapler", "staple"]:
    (Path(args[-1]) / "Contents/test-ticket").write_text("fixture ticket")
'''


class SigningTests(unittest.TestCase):
    def setUp(self):
        (ROOT / "build").mkdir(exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="signing test ", dir=ROOT / "build")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        for relative in ["scripts/build-and-run.sh", "Resources/Info.plist", "Resources/ezkey.entitlements", "LICENSE"]:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        tool = self.bin / "tool"
        tool.write_text(f"#!{sys.executable}\n" + TOOL)
        tool.chmod(0o755)
        for command in ["swift", "codesign", "xcrun", "open", "pkill"]:
            (self.bin / command).symlink_to(tool)
        self.log = self.root / "commands.jsonl"
        self.app = self.root / "build/ezkey.app"
        self.installed = self.root / "Applications/ezkey.app"
        self.env = {
            key: value for key, value in os.environ.items()
            if not key.startswith(("EZKEY_", "SKIP_", "SIGNING_TEST_"))
        }
        self.env.update({
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "SIGNING_TEST_LOG": str(self.log),
            "EZKEY_INSTALL_DIR": str(self.installed.parent),
        })

    def run_build(self, expected_code=0, **variables):
        self.log.unlink(missing_ok=True)
        result = subprocess.run(
            ["/bin/zsh", str(self.root / "scripts/build-and-run.sh")],
            cwd=self.root, env=self.env | variables, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, expected_code, result.stdout + result.stderr)
        self.events = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        return result

    def signatures(self):
        return [event for event in self.events if event["command"] == "codesign" and event["args"][0] == "--force"]

    def test_identifiers_and_entitlements(self):
        with (ROOT / "Resources/ezkey.entitlements").open("rb") as file:
            self.assertEqual(plistlib.load(file), {
                "com.apple.application-identifier": "W3N4GBR8TB.app.ezkey",
                "com.apple.developer.team-identifier": "W3N4GBR8TB",
                "keychain-access-groups": ["W3N4GBR8TB.app.ezkey"],
            })
        with (ROOT / "Resources/Info.plist").open("rb") as file:
            self.assertEqual(plistlib.load(file)["CFBundleIdentifier"], "app.ezkey")

    def test_default_build_and_install_keep_ad_hoc_and_self_test(self):
        self.run_build()
        self.assertEqual([event["command"] for event in self.events], [
            "swift", "swift", "codesign", "codesign", "ezkey", "codesign", "codesign", "pkill", "open",
        ])
        self.assertEqual(self.events[0]["args"], ["test", "--package-path", str(self.root)])
        self.assertEqual(self.events[4]["args"], ["--self-test"])
        for event, app in zip(self.signatures(), [self.app, self.installed]):
            self.assertEqual(event["args"], ["--force", "--sign", "-", "--identifier", "app.ezkey", str(app)])
            self.assertEqual(event["profile"], None)
        self.assertEqual(self.events[3]["args"], ["--verify", "--deep", "--strict", str(self.app)])
        self.assertEqual(self.events[6]["args"], ["--verify", "--deep", "--strict", str(self.installed)])
        self.assertEqual(self.events[-1]["args"], [str(self.installed)])
        self.assertEqual((self.installed / "Contents/PkgInfo").read_text(), "APPL????")

    def test_ci_skips_and_empty_identity_ignore_signing_inputs(self):
        self.run_build(SKIP_TESTS="1", SKIP_VERIFY="1", SKIP_INSTALL="1", EZKEY_SIGN_IDENTITY="",
                       EZKEY_ENTITLEMENTS="missing.entitlements", EZKEY_PROFILE="missing.provisionprofile")
        self.assertEqual([event["command"] for event in self.events], ["swift", "codesign", "codesign"])
        self.assertEqual(self.signatures()[0]["args"], [
            "--force", "--sign", "-", "--identifier", "app.ezkey", str(self.app),
        ])
        self.assertEqual(self.signatures()[0]["profile"], None)
        self.assertFalse(self.installed.exists())

    def test_profile_is_embedded_before_both_signatures(self):
        profile = self.root / "fixture profile.provisionprofile"
        profile.write_text("fixture profile")
        for _ in range(2):
            self.run_build(EZKEY_SIGN_IDENTITY="Developer ID Application: Example", EZKEY_PROFILE=str(profile), SKIP_LAUNCH="1")
            signatures = self.signatures()
            self.assertEqual(len(signatures), 2)
            for event, app in zip(signatures, [self.app, self.installed]):
                self.assertEqual(event["profile"], "fixture profile")
                self.assertEqual(event["args"], [
                    "--force", "--options", "runtime", "--timestamp", "--entitlements",
                    str(self.root / "Resources/ezkey.entitlements"), "--sign", "Developer ID Application: Example",
                    "--identifier", "app.ezkey", str(app),
                ])
                self.assertEqual((app / "Contents/embedded.provisionprofile").read_text(), "fixture profile")
            self.assertEqual(self.events[-1]["args"], ["--verify", "--deep", "--strict", str(self.installed)])
        self.run_build(SKIP_LAUNCH="1")
        self.assertEqual([event["profile"] for event in self.signatures()], [None, None])

    def test_custom_entitlements_and_missing_profile_warning(self):
        entitlements = self.root / "custom entitlements.plist"
        shutil.copyfile(self.root / "Resources/ezkey.entitlements", entitlements)
        result = self.run_build(EZKEY_SIGN_IDENTITY="Developer ID Application: Example", EZKEY_ENTITLEMENTS=entitlements.name, SKIP_INSTALL="1")
        self.assertEqual(self.signatures()[0]["args"][4:6], ["--entitlements", entitlements.name])
        self.assertIn("AMFI kills the app at launch", result.stderr)

    def test_plain_local_identity_opt_out(self):
        result = self.run_build(EZKEY_SIGN_IDENTITY="Local Signing Identity", EZKEY_ENTITLEMENTS="none", SKIP_LAUNCH="1")
        for event, app in zip(self.signatures(), [self.app, self.installed]):
            self.assertEqual(event["args"], [
                "--force", "--options", "runtime", "--timestamp", "--sign", "Local Signing Identity",
                "--identifier", "app.ezkey", str(app),
            ])
        self.assertEqual(result.stderr, "")

    def test_invalid_inputs_fail_before_build(self):
        cases = [
            ({"EZKEY_SIGN_IDENTITY": "Local", "EZKEY_ENTITLEMENTS": "missing.plist"}, "Entitlements file not found: missing.plist"),
            ({"EZKEY_SIGN_IDENTITY": "Local", "EZKEY_PROFILE": "missing.profile"}, "Provisioning profile not found: missing.profile"),
            ({"EZKEY_NOTARY_PROFILE": "fixture"}, "cannot notarize an ad hoc build"),
            ({"EZKEY_SIGN_IDENTITY": "-", "EZKEY_NOTARY_PROFILE": "fixture"}, "cannot notarize an ad hoc build"),
        ]
        for variables, message in cases:
            with self.subTest(variables=variables):
                result = self.run_build(expected_code=1, **variables)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.events, [])

    def test_notary_staples_build_and_installs_without_resigning(self):
        for _ in range(2):
            self.run_build(EZKEY_SIGN_IDENTITY="Local", EZKEY_ENTITLEMENTS="none", EZKEY_NOTARY_PROFILE="fixture-notary", SKIP_LAUNCH="1")
            self.assertEqual(len(self.signatures()), 1)
            self.assertEqual([event["command"] for event in self.events], [
                "swift", "swift", "codesign", "codesign", "ezkey", "xcrun", "xcrun", "codesign", "codesign",
            ])
            self.assertEqual(self.events[5]["args"], [
                "notarytool", "submit", str(self.root / "build/ezkey-notary.zip"), "--keychain-profile", "fixture-notary", "--wait",
            ])
            self.assertEqual(self.events[6]["args"], ["stapler", "staple", str(self.app)])
            self.assertEqual(self.events[7]["args"], ["--verify", "--deep", "--strict", str(self.app)])
            self.assertEqual(self.events[8]["args"], ["--verify", "--deep", "--strict", str(self.installed)])
            self.assertEqual((self.installed / "Contents/test-ticket").read_text(), "fixture ticket")
            with zipfile.ZipFile(self.root / "build/ezkey-notary.zip") as archive:
                self.assertEqual(archive.read("ezkey.app/Contents/PkgInfo"), b"APPL????")
                self.assertNotIn("ezkey.app/Contents/test-ticket", archive.namelist())

    def test_failed_notary_or_verification_never_installs(self):
        for command in ["xcrun notarytool submit", "xcrun stapler staple", "codesign --verify --deep"]:
            with self.subTest(command=command):
                self.run_build(expected_code=42, EZKEY_SIGN_IDENTITY="Local", EZKEY_ENTITLEMENTS="none",
                               EZKEY_NOTARY_PROFILE="fixture-notary", SIGNING_TEST_FAIL=command)
                self.assertFalse(self.installed.exists())
                self.assertEqual(" ".join([self.events[-1]["command"]] + self.events[-1]["args"][:2]), command)


if __name__ == "__main__":
    unittest.main()
