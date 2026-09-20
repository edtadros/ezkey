import XCTest
@testable import EZKeyCore

actor MockStore: SecretStore {
    var items: [SecretIdentity: String] = [:]
    var retrieveHandler: (@Sendable (SecretIdentity) async throws -> String)?

    func contains(_ identity: SecretIdentity) async throws -> Bool {
        items[identity] != nil
    }

    func add(_ identity: SecretIdentity, secret: String) async throws {
        if items[identity] != nil { throw KeychainError.duplicateEntry }
        items[identity] = secret
    }

    func update(_ identity: SecretIdentity, secret: String) async throws {
        guard items[identity] != nil else { throw KeychainError.missingEntry }
        items[identity] = secret
    }

    func retrieve(_ identity: SecretIdentity) async throws -> String {
        if let retrieveHandler {
            return try await retrieveHandler(identity)
        }
        guard let secret = items[identity] else { throw KeychainError.missingEntry }
        return secret
    }

    func list(matching query: String) async throws -> [SecretIdentity] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return items.keys
            .filter {
                $0.service.localizedCaseInsensitiveContains(needle)
                    || $0.account.localizedCaseInsensitiveContains(needle)
            }
            .sorted { ($0.service, $0.account) < ($1.service, $1.account) }
    }

    func delete(_ identity: SecretIdentity) async throws {
        items[identity] = nil
    }

    func secret(for identity: SecretIdentity) -> String? {
        items[identity]
    }

    func setRetrieveHandler(_ handler: (@Sendable (SecretIdentity) async throws -> String)?) {
        retrieveHandler = handler
    }

    func seed(_ identity: SecretIdentity, secret: String) {
        items[identity] = secret
    }
}

actor Gate {
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
final class MockPasteboard: PasteboardWriting {
    var value: String?

    func write(_ string: String) { value = string }
    func read() -> String? { value }
    func clear() { value = nil }
}

@MainActor
final class PanelModelTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var store: MockStore!
    private var pasteboard: MockPasteboard!
    private var sleeper: ManualSleeper!
    private var model: PanelModel!

    override func setUp() async throws {
        suiteName = "ezkey.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = MockStore()
        pasteboard = MockPasteboard()
        sleeper = ManualSleeper()
        let clipboard = ClipboardGuard(pasteboard: pasteboard, sleeper: sleeper, clearAfter: .milliseconds(1))
        model = PanelModel(
            store: store,
            clipboard: clipboard,
            defaults: defaults,
            currentUser: "testuser"
        )
        model.panelDidOpen()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testAccountDefaultsToCurrentUser() {
        XCTAssertEqual(model.account, "testuser")
    }

    func testSaveRejectsBlankIdentity() async {
        model.service = "  "
        model.secretToSave = "secret"
        await model.save()
        XCTAssertEqual(model.status, .validation("Name and account are required."))
    }

    func testSaveRejectsEmptySecret() async {
        model.service = "ezkey.test.save"
        model.secretToSave = ""
        await model.save()
        XCTAssertEqual(model.status, .validation("Enter a secret to save."))
    }

    func testSaveCreatesNewEntry() async {
        model.service = "ezkey.test.save"
        model.secretToSave = "s3cret"
        await model.save()
        XCTAssertEqual(model.status, .saved)
        XCTAssertEqual(model.secretToSave, "")
        let stored = await store.secret(for: model.identity)
        XCTAssertEqual(stored, "s3cret")
    }

    func testSaveRequiresExplicitUpdateWhenEntryExists() async {
        let identity = SecretIdentity(service: "ezkey.test.dup", account: "testuser")
        await store.seed(identity, secret: "old")
        model.service = identity.service
        model.account = identity.account
        model.secretToSave = "new"
        await model.save()
        XCTAssertEqual(model.status, .needsUpdate)
        let stored = await store.secret(for: identity)
        XCTAssertEqual(stored, "old")
        XCTAssertEqual(model.secretToSave, "new")
    }

    func testUpdateReplacesExistingValue() async {
        let identity = SecretIdentity(service: "ezkey.test.upd", account: "testuser")
        await store.seed(identity, secret: "old")
        model.service = identity.service
        model.account = identity.account
        model.secretToSave = "new"
        await model.save()
        XCTAssertEqual(model.status, .needsUpdate)
        await model.update()
        XCTAssertEqual(model.status, .updated)
        let stored = await store.secret(for: identity)
        XCTAssertEqual(stored, "new")
        XCTAssertEqual(model.secretToSave, "")
    }

    func testChangingIdentityClearsNeedsUpdate() async {
        let identity = SecretIdentity(service: "ezkey.test.need", account: "testuser")
        await store.seed(identity, secret: "old")
        model.service = identity.service
        model.account = identity.account
        model.secretToSave = "new"
        await model.save()
        XCTAssertEqual(model.status, .needsUpdate)
        model.service = "ezkey.test.other"
        XCTAssertEqual(model.status, .idle)
    }

    func testRetrieveMissingEntry() async {
        model.service = "ezkey.test.missing"
        await model.retrieve()
        XCTAssertEqual(model.status, .noMatches)
        XCTAssertNil(model.retrievedSecret)
        XCTAssertTrue(model.matches.isEmpty)
    }

    func testRetrieveCancelledAndDenied() async {
        let identity = SecretIdentity(service: "ezkey.test.cancel", account: "testuser")
        await store.seed(identity, secret: "hidden")
        model.service = identity.service
        await store.setRetrieveHandler { _ in throw KeychainError.cancelled }
        await model.retrieve()
        XCTAssertEqual(model.status, .cancelled)

        await store.setRetrieveHandler { _ in throw KeychainError.accessDenied }
        await model.retrieve()
        XCTAssertEqual(model.status, .accessDenied)
    }

    func testPartialRetrieveListsMatchesWithoutSecrets() async {
        let staging = SecretIdentity(service: "callbrief/staging/xai", account: "testuser")
        let prod = SecretIdentity(service: "callbrief/prod/xai", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "callbrief"
        await model.retrieve()
        XCTAssertEqual(model.status, .chooseMatch)
        XCTAssertNil(model.retrievedSecret)
        XCTAssertEqual(model.matches.map(\.service), ["callbrief/prod/xai", "callbrief/staging/xai"])
    }

    func testSelectingAMatchRetrievesThatSecret() async {
        let staging = SecretIdentity(service: "callbrief/staging/xai", account: "testuser")
        let prod = SecretIdentity(service: "callbrief/prod/xai", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "callbrief"
        await model.retrieve()
        await model.selectMatch(staging)
        XCTAssertEqual(model.status, .retrieved)
        XCTAssertEqual(model.retrievedSecret, "staging-secret")
        XCTAssertEqual(model.service, staging.service)
        XCTAssertTrue(model.matches.isEmpty)
    }

    func testRetrieveIsMaskedUntilRevealed() async {
        let identity = SecretIdentity(service: "ezkey.test.mask", account: "testuser")
        await store.seed(identity, secret: "hidden-value")
        model.service = identity.service
        await model.retrieve()
        XCTAssertEqual(model.status, .retrieved)
        XCTAssertEqual(model.retrievedSecret, "hidden-value")
        XCTAssertFalse(model.isRevealed)
        model.toggleReveal()
        XCTAssertTrue(model.isRevealed)
        model.toggleReveal()
        XCTAssertFalse(model.isRevealed)
    }

    func testCopyUsesClipboard() async {
        let identity = SecretIdentity(service: "ezkey.test.copy", account: "testuser")
        await store.seed(identity, secret: "copy-me")
        model.service = identity.service
        await model.retrieve()
        model.copyRetrieved()
        XCTAssertEqual(model.status, .copied)
        XCTAssertEqual(pasteboard.value, "copy-me")
    }

    func testPanelCloseClearsSecretsAndPersistsLabels() async {
        model.service = "ezkey.test.close"
        model.secretToSave = "draft-secret"
        model.retrievedSecret = "retrieved-secret"
        model.isRevealed = true
        model.panelDidClose()
        XCTAssertEqual(model.secretToSave, "")
        XCTAssertNil(model.retrievedSecret)
        XCTAssertFalse(model.isRevealed)
        XCTAssertEqual(model.status, .idle)
        XCTAssertEqual(defaults.string(forKey: PanelModel.serviceDefaultsKey), "ezkey.test.close")
        XCTAssertEqual(defaults.string(forKey: PanelModel.accountDefaultsKey), "testuser")
    }

    func testInFlightRetrieveSurvivesKeychainDialogDismissingPanel() async {
        let gate = Gate()
        var reopenCount = 0
        model.onOperationFinishedWhileClosed = { reopenCount += 1 }
        let identity = SecretIdentity(service: "ezkey.test.inflight", account: "testuser")
        await store.seed(identity, secret: "placeholder")
        await store.setRetrieveHandler { _ in
            await gate.wait()
            return "late-secret"
        }
        model.service = identity.service
        let task = Task { await model.retrieve() }
        for _ in 0..<100 where model.status != .working {
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertEqual(model.status, .working)
        model.panelDidClose()
        await gate.open()
        await task.value
        XCTAssertEqual(model.retrievedSecret, "late-secret")
        XCTAssertFalse(model.isRevealed)
        XCTAssertEqual(model.status, .retrieved)
        XCTAssertFalse(model.isPanelOpen)
        XCTAssertEqual(reopenCount, 1)
    }

    func testModeSwitchClearsRetrievedSecret() async {
        let identity = SecretIdentity(service: "ezkey.test.mode", account: "testuser")
        await store.seed(identity, secret: "value")
        model.service = identity.service
        model.mode = .retrieve
        await model.retrieve()
        XCTAssertEqual(model.retrievedSecret, "value")
        model.mode = .save
        XCTAssertNil(model.retrievedSecret)
    }
}
