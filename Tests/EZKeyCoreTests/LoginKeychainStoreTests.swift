import Foundation
import XCTest
@testable import EZKeyCore

final class LoginKeychainStoreTests: XCTestCase {
    /// Unsigned xctest cannot cross the security(1) ACL without a login-keychain
    /// password prompt, so these tests stay same-process. CLI interop is covered
    /// by scripts/verify-roundtrip.swift after the app is signed.
    /// Round-trip tests save with `.trustEzkey` so they can read back without a
    /// prompt; the app uses `.askEveryTime`, covered by the tests at the end.
    private let store = LoginKeychainStore(allowsPrompt: false, readPolicy: .trustEzkey)
    private let askEveryTime = LoginKeychainStore(allowsPrompt: false)
    private var created: [SecretIdentity] = []

    override func tearDown() async throws {
        for identity in created {
            XCTAssertTrue(
                DisposableEntry.isDisposable(identity),
                "refusing to delete a non-disposable entry"
            )
            try? await store.delete(identity)
        }
        created.removeAll()
    }

    func testAddThenRetrieve() async throws {
        let identity = uniqueIdentity()
        let secret = "same-process-\(UUID().uuidString)"
        try await store.add(identity, secret: secret)
        created.append(identity)
        let got = try await store.retrieve(identity)
        XCTAssertTrue(got.secret == secret, "secret mismatch")
        XCTAssertEqual(got.note, "")
    }

    func testUpdateDoesNotChangeAnotherPair() async throws {
        let first = uniqueIdentity()
        let second = uniqueIdentity()
        try await store.add(first, secret: "first-secret")
        try await store.add(second, secret: "second-secret")
        created.append(contentsOf: [first, second])
        try await store.update(first, secret: "first-updated")
        let firstGot = try await store.retrieve(first)
        let secondGot = try await store.retrieve(second)
        XCTAssertTrue(firstGot.secret == "first-updated", "updated pair mismatch")
        XCTAssertTrue(secondGot.secret == "second-secret", "untouched pair was changed")
    }

    func testMissingEntry() async throws {
        let identity = uniqueIdentity()
        do {
            _ = try await store.retrieve(identity)
            XCTFail("expected missing entry")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .missingEntry)
        } catch {
            XCTFail("unexpected error type")
        }
        let exists = try await store.contains(identity)
        XCTAssertFalse(exists)
    }

    func testExactRoundTripForSpacesQuotesAndUnicode() async throws {
        let identity = uniqueIdentity()
        let secret = "  lead space \"quoted\" café αβγ 🔑 trail "
        try await store.add(identity, secret: secret)
        created.append(identity)
        let got = try await store.retrieve(identity)
        XCTAssertTrue(got.secret == secret, "store round trip mismatch")
    }

    func testDuplicateAddDoesNotOverwrite() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "one")
        created.append(identity)
        do {
            try await store.add(identity, secret: "two")
            XCTFail("expected duplicate")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .duplicateEntry)
        }
        let got = try await store.retrieve(identity)
        XCTAssertTrue(got.secret == "one", "duplicate add overwrote the secret")
    }

    func testContainsDoesNotRequireReturningSecret() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "exists")
        created.append(identity)
        let exists = try await store.contains(identity)
        XCTAssertTrue(exists)
    }

    func testListMatchingIsSubstringAndDoesNotReturnSecrets() async throws {
        let token = UUID().uuidString
        let first = SecretIdentity(service: DisposableEntry.servicePrefix + token + ".alpha", account: NSUserName())
        let second = SecretIdentity(service: DisposableEntry.servicePrefix + token + ".beta", account: NSUserName())
        let other = uniqueIdentity()
        try await store.add(first, secret: "alpha-secret")
        try await store.add(second, secret: "beta-secret")
        try await store.add(other, secret: "other-secret")
        created.append(contentsOf: [first, second, other])
        let matches = try await store.list(matching: token)
        XCTAssertEqual(Set(matches.map(\.service)), [first.service, second.service])
        XCTAssertFalse(matches.contains(other))
    }

    func testCommentRoundTrip() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "secret-with-note", note: "  staging token for local tools  ")
        created.append(identity)
        let got = try await store.retrieve(identity)
        XCTAssertEqual(got.secret, "secret-with-note")
        XCTAssertEqual(got.note, "staging token for local tools")
        let comment = try await store.comment(for: identity)
        XCTAssertEqual(comment, "staging token for local tools")
    }

    func testUpdateReplacesNote() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "secret", note: "old-note")
        created.append(identity)
        try await store.update(identity, secret: "secret", note: "rotated 2026-09")
        let got = try await store.retrieve(identity)
        XCTAssertEqual(got.secret, "secret")
        XCTAssertEqual(got.note, "rotated 2026-09")
    }

    func testUpdateCanClearNote() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "secret", note: "temporary")
        created.append(identity)
        try await store.update(identity, secret: "secret", note: "")
        let got = try await store.retrieve(identity)
        XCTAssertEqual(got.secret, "secret")
        XCTAssertEqual(got.note, "")
    }

    func testListMatchingFindsComment() async throws {
        let token = UUID().uuidString
        let named = SecretIdentity(service: DisposableEntry.servicePrefix + token + ".named", account: NSUserName())
        let noted = SecretIdentity(service: DisposableEntry.servicePrefix + UUID().uuidString, account: NSUserName())
        try await store.add(named, secret: "named-secret")
        try await store.add(noted, secret: "noted-secret", note: "marker \(token) in comments")
        created.append(contentsOf: [named, noted])
        let matches = try await store.list(matching: token)
        XCTAssertEqual(Set(matches.map(\.service)), [named.service, noted.service])
    }

    func testAskEveryTimeRefusesASilentReadEvenByEzkey() async throws {
        let identity = uniqueIdentity()
        try await askEveryTime.add(identity, secret: "needs-a-password")
        created.append(identity)
        do {
            _ = try await askEveryTime.retrieve(identity)
            XCTFail("read the secret without the password prompt")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .accessDenied)
        }
    }

    func testAskEveryTimeItemTrustsNoAppToRead() async throws {
        let identity = uniqueIdentity()
        try await askEveryTime.add(identity, secret: "needs-a-password")
        created.append(identity)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: identity.service,
            kSecAttrAccount: identity.account,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: false,
        ]
        var ref: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &ref), errSecSuccess)
        var access: SecAccess?
        XCTAssertEqual(SecKeychainItemCopyAccess(ref as! SecKeychainItem, &access), errSecSuccess)
        let decrypt = SecAccessCopyMatchingACLList(access!, kSecACLAuthorizationDecrypt) as! [SecACL]
        XCTAssertFalse(decrypt.isEmpty)
        for acl in decrypt {
            var apps: CFArray?
            var description: CFString?
            var selector = SecKeychainPromptSelector()
            XCTAssertEqual(SecACLCopyContents(acl, &apps, &description, &selector), errSecSuccess)
            XCTAssertEqual((apps as? [Any])?.count, 0, "an app can read without the prompt")
        }
    }

    func testAskEveryTimeKeepsNamesNotesAndDeleteSilent() async throws {
        let token = UUID().uuidString
        let identity = SecretIdentity(service: DisposableEntry.servicePrefix + token, account: NSUserName())
        try await askEveryTime.add(identity, secret: "first", note: "note \(token)")
        created.append(identity)
        let exists = try await askEveryTime.contains(identity)
        XCTAssertTrue(exists)
        let comment = try await askEveryTime.comment(for: identity)
        XCTAssertEqual(comment, "note \(token)")
        let matches = try await askEveryTime.list(matching: token)
        XCTAssertEqual(matches, [identity])
        try await askEveryTime.delete(identity)
        let gone = try await askEveryTime.contains(identity)
        XCTAssertFalse(gone)
    }

    func testUpdateNeedsThePasswordBeforeReplacingASecret() async throws {
        let identity = uniqueIdentity()
        try await askEveryTime.add(identity, secret: "original", note: "before")
        created.append(identity)
        do {
            try await askEveryTime.update(identity, secret: "overwrite", note: "after")
            XCTFail("replaced a secret without the password prompt")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .accessDenied)
        }
        let note = try await askEveryTime.comment(for: identity)
        XCTAssertEqual(note, "before", "the refused update still changed the item")
    }

    func testRefusesToTreatProductionServiceAsDisposable() {
        let production = SecretIdentity(service: "mail/prod", account: NSUserName())
        XCTAssertFalse(DisposableEntry.isDisposable(production))
    }

    private func uniqueIdentity() -> SecretIdentity {
        SecretIdentity(
            service: DisposableEntry.servicePrefix + UUID().uuidString,
            account: NSUserName()
        )
    }
}
