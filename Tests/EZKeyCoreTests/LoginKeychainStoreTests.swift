import Foundation
import XCTest
@testable import EZKeyCore

final class LoginKeychainStoreTests: XCTestCase {
    /// Unsigned xctest cannot cross the security(1) ACL without a login-keychain
    /// password prompt, so these tests stay same-process. CLI interop is covered
    /// by scripts/verify-roundtrip.swift after the app is signed.
    private let store = LoginKeychainStore(allowsPrompt: false)
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
        XCTAssertTrue(got == secret, "secret mismatch")
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
        XCTAssertTrue(firstGot == "first-updated", "updated pair mismatch")
        XCTAssertTrue(secondGot == "second-secret", "untouched pair was changed")
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
        XCTAssertTrue(got == secret, "store round trip mismatch")
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
        XCTAssertTrue(got == "one", "duplicate add overwrote the secret")
    }

    func testContainsDoesNotRequireReturningSecret() async throws {
        let identity = uniqueIdentity()
        try await store.add(identity, secret: "exists")
        created.append(identity)
        let exists = try await store.contains(identity)
        XCTAssertTrue(exists)
    }

    func testRefusesToTreatProductionServiceAsDisposable() {
        let production = SecretIdentity(service: "phishhook/jev", account: NSUserName())
        XCTAssertFalse(DisposableEntry.isDisposable(production))
    }

    private func uniqueIdentity() -> SecretIdentity {
        SecretIdentity(
            service: DisposableEntry.servicePrefix + UUID().uuidString,
            account: NSUserName()
        )
    }
}
