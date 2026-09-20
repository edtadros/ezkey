import Security
import XCTest
@testable import EZKeyCore

final class ModelsTests: XCTestCase {
    func testIdentityTrimsServiceAndAccount() {
        let identity = SecretIdentity(service: "  my-app/api-token  ", account: "  alice  ")
        XCTAssertEqual(identity.service, "my-app/api-token")
        XCTAssertEqual(identity.account, "alice")
        XCTAssertTrue(identity.isValid)
    }

    func testIdentityRejectsBlankFields() {
        XCTAssertFalse(SecretIdentity(service: "  ", account: "alice").isValid)
        XCTAssertFalse(SecretIdentity(service: "svc", account: " \n ").isValid)
    }

    func testKeychainErrorMapping() {
        XCTAssertEqual(KeychainError.from(status: errSecItemNotFound), .missingEntry)
        XCTAssertEqual(KeychainError.from(status: errSecDuplicateItem), .duplicateEntry)
        XCTAssertEqual(KeychainError.from(status: errSecUserCanceled), .cancelled)
        XCTAssertEqual(KeychainError.from(status: errSecAuthFailed), .accessDenied)
        XCTAssertEqual(KeychainError.from(status: errSecInteractionNotAllowed), .accessDenied)
        XCTAssertEqual(KeychainError.from(status: errSecWrPerm), .accessDenied)
        XCTAssertEqual(KeychainError.from(status: errSecParam), .failure(errSecParam))
    }

    func testOperationStatusMessagesAreSpecific() {
        XCTAssertEqual(OperationStatus.saved.message, "Saved.")
        XCTAssertEqual(OperationStatus.updated.message, "Updated.")
        XCTAssertTrue(OperationStatus.needsUpdate.message.contains("Update"))
        XCTAssertEqual(OperationStatus.missingEntry.message, "No entry for this name and account.")
        XCTAssertEqual(OperationStatus.accessDenied.message, "Keychain access denied.")
        XCTAssertEqual(OperationStatus.cancelled.message, "Keychain access cancelled.")
        XCTAssertEqual(OperationStatus.from(error: .duplicateEntry), .needsUpdate)
    }

    func testStoredSecretNoteHelpers() {
        XCTAssertTrue(StoredSecret(secret: "x", note: "keep").hasNote)
        XCTAssertFalse(StoredSecret(secret: "x", note: "  \n").hasNote)
        XCTAssertEqual(StoredSecret.normalizedNote("  keep this  "), "keep this")
    }

    func testDisposablePrefixNeverMatchesProductionService() {
        XCTAssertTrue(DisposableEntry.isDisposable(SecretIdentity(service: "ezkey.test.abc", account: "a")))
        XCTAssertFalse(DisposableEntry.isDisposable(SecretIdentity(service: "mail/prod", account: "a")))
    }
}
