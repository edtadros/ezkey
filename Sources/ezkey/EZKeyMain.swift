import Foundation
import EZKeyCore

/// Headless checks against the signed app binary and login.keychain-db.
/// Mutates only `ezkey.test.*` items. Never prints secret values.
enum SelfTest {
    static func run() async -> Int32 {
        let store = LoginKeychainStore(allowsPrompt: false)
        let loginPath = LoginKeychainStore.defaultLoginPath
        let account = NSUserName()
        var failures = 0
        var created: [SecretIdentity] = []

        func pass(_ name: String) { print("PASS \(name)") }
        func fail(_ name: String, _ detail: String) {
            failures += 1
            fputs("FAIL \(name) \(detail)\n", stderr)
        }

        do {
            let identity = SecretIdentity(
                service: DisposableEntry.servicePrefix + "self.\(UUID().uuidString)",
                account: account
            )
            let secret = "  self-test \"quoted\" café 🔑 "
            try await store.add(identity, secret: secret)
            created.append(identity)

            let retrieved = try await store.retrieve(identity)
            if retrieved == secret {
                pass("same-process-roundtrip")
            } else {
                fail("same-process-roundtrip", "mismatch")
            }

            if try await store.contains(identity) {
                pass("contains-without-returning-secret")
            } else {
                fail("contains-without-returning-secret", "missing")
            }

            let existsViaCLI = securityItemExists(
                service: identity.service,
                account: account,
                keychain: loginPath
            )
            if existsViaCLI {
                pass("app-add-visible-to-security-cli")
            } else {
                fail("app-add-visible-to-security-cli", "security(1) did not find the item in login.keychain-db")
            }

            let fromCLI = SecretIdentity(
                service: DisposableEntry.servicePrefix + "self.cli.\(UUID().uuidString)",
                account: account
            )
            let cliSecret = "cli-created-\(UUID().uuidString)"
            let addCode = securityAdd(identity: fromCLI, secret: cliSecret, keychain: loginPath)
            if addCode == 0 {
                created.append(fromCLI)
                if try await store.contains(fromCLI) {
                    pass("cli-add-visible-to-app")
                } else {
                    fail("cli-add-visible-to-app", "contains returned false")
                }
            } else {
                fail("cli-add-visible-to-app", "security add exit=\(addCode)")
            }

            let other = SecretIdentity(
                service: DisposableEntry.servicePrefix + "self.other.\(UUID().uuidString)",
                account: account
            )
            try await store.add(other, secret: "other-secret")
            created.append(other)
            try await store.update(identity, secret: "updated-secret")
            let first = try await store.retrieve(identity)
            let second = try await store.retrieve(other)
            if first == "updated-secret", second == "other-secret" {
                pass("update-does-not-clobber-other-pair")
            } else {
                fail("update-does-not-clobber-other-pair", "values diverged")
            }

            let missing = SecretIdentity(
                service: DisposableEntry.servicePrefix + "self.missing.\(UUID().uuidString)",
                account: account
            )
            do {
                _ = try await store.retrieve(missing)
                fail("missing-entry", "unexpected success")
            } catch KeychainError.missingEntry {
                pass("missing-entry")
            } catch {
                fail("missing-entry", "wrong error")
            }
        } catch {
            fail("self-test", "threw")
        }

        for identity in created where DisposableEntry.isDisposable(identity) {
            try? await store.delete(identity)
            _ = runSecurity([
                "delete-generic-password",
                "-a", identity.account,
                "-s", identity.service,
                loginPath
            ])
        }

        if failures == 0 {
            print("all self-test checks passed")
            return 0
        }
        return 1
    }

    /// Attribute lookup only. Reading the password with `-w` can present a
    /// Keychain prompt, which is expected for a different process.
    private static func securityItemExists(service: String, account: String, keychain: String) -> Bool {
        runSecurity([
            "find-generic-password",
            "-a", account,
            "-s", service,
            keychain
        ]) == 0
    }

    private static func securityAdd(identity: SecretIdentity, secret: String, keychain: String) -> Int32 {
        guard DisposableEntry.isDisposable(identity) else { return -1 }
        return runSecurity([
            "add-generic-password",
            "-U",
            "-A",
            "-a", identity.account,
            "-s", identity.service,
            "-w", secret,
            keychain
        ])
    }

    private static func runSecurity(_ arguments: [String], timeout: TimeInterval = 8) -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = arguments
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        let group = DispatchGroup()
        group.enter()
        proc.terminationHandler = { _ in group.leave() }
        do { try proc.run() } catch { return -1 }
        if group.wait(timeout: .now() + timeout) == .timedOut {
            proc.terminate()
            return -2
        }
        return proc.terminationStatus
    }
}
