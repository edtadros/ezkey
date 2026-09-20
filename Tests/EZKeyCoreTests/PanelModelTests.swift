import XCTest
@testable import EZKeyCore

actor MockStore: SecretStore {
    var items: [SecretIdentity: StoredSecret] = [:]
    var retrieveHandler: (@Sendable (SecretIdentity) async throws -> StoredSecret)?

    func contains(_ identity: SecretIdentity) async throws -> Bool {
        items[identity] != nil
    }

    func add(_ identity: SecretIdentity, secret: String, note: String) async throws {
        if items[identity] != nil { throw KeychainError.duplicateEntry }
        items[identity] = StoredSecret(secret: secret, note: note)
    }

    func update(_ identity: SecretIdentity, secret: String, note: String) async throws {
        guard items[identity] != nil else { throw KeychainError.missingEntry }
        items[identity] = StoredSecret(secret: secret, note: note)
    }

    func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret {
        if let retrieveHandler {
            return try await retrieveHandler(identity)
        }
        guard let stored = items[identity] else { throw KeychainError.missingEntry }
        return stored
    }

    func comment(for identity: SecretIdentity) async throws -> String {
        guard let stored = items[identity] else { throw KeychainError.missingEntry }
        return stored.note
    }

    func list(matching query: String) async throws -> [SecretIdentity] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return items.keys
            .filter {
                $0.service.localizedCaseInsensitiveContains(needle)
                    || $0.account.localizedCaseInsensitiveContains(needle)
                    || (items[$0]?.note.localizedCaseInsensitiveContains(needle) ?? false)
            }
            .sorted { ($0.service, $0.account) < ($1.service, $1.account) }
    }

    func delete(_ identity: SecretIdentity) async throws {
        items[identity] = nil
    }

    func secret(for identity: SecretIdentity) -> String? {
        items[identity]?.secret
    }

    func setRetrieveHandler(_ handler: (@Sendable (SecretIdentity) async throws -> StoredSecret)?) {
        retrieveHandler = handler
    }

    func seed(_ identity: SecretIdentity, secret: String, note: String = "") {
        items[identity] = StoredSecret(secret: secret, note: note)
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
        XCTAssertEqual(model.status, .validation("Name is required."))
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
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        XCTAssertEqual(model.status, .chooseMatch)
        XCTAssertNil(model.retrievedSecret)
        XCTAssertEqual(model.matches.map(\.service), ["myapp/prod/llm", "myapp/staging/llm"])
    }

    func testSelectingAMatchRetrievesThatSecret() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        await model.selectMatch(staging)
        XCTAssertEqual(model.status, .retrieved)
        XCTAssertEqual(model.retrievedSecret, "staging-secret")
        XCTAssertEqual(model.service, staging.service)
        XCTAssertTrue(model.matches.isEmpty)
    }

    func testSelectingAMatchThenCopyPutsSecretOnClipboard() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        await model.selectMatch(staging)
        model.copyRetrieved()
        XCTAssertEqual(model.status, .copied)
        XCTAssertEqual(pasteboard.value, "staging-secret")
    }

    func testPanelDidOpenDoesNotClearRetrieveMatches() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        XCTAssertEqual(model.status, .chooseMatch)
        XCTAssertEqual(model.matches.count, 2)
        model.panelDidOpen()
        XCTAssertEqual(model.status, .chooseMatch)
        XCTAssertEqual(model.matches.map(\.service), ["myapp/prod/llm", "myapp/staging/llm"])
    }

    func testReassigningSameServiceDoesNotClearMatches() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        model.service = "myapp"
        model.account = "testuser"
        XCTAssertEqual(model.status, .chooseMatch)
        XCTAssertEqual(model.matches.count, 2)
    }

    func testEditingServiceClearsRetrieveMatches() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret")
        await store.seed(prod, secret: "prod-secret")
        model.service = "myapp"
        await model.retrieve()
        model.service = "myapp/prod"
        XCTAssertEqual(model.status, .idle)
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
            return StoredSecret(secret: "late-secret", note: "late-note")
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
        XCTAssertEqual(model.retrievedNote, "late-note")
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
        XCTAssertNil(model.retrievedNote)
    }

    func testSavePersistsNote() async throws {
        model.service = "ezkey.test.note-save"
        model.secretToSave = "secret"
        model.noteToSave = "  staging token for local tools  "
        await model.save()
        XCTAssertEqual(model.status, .saved)
        XCTAssertEqual(model.noteToSave, "")
        let stored = try await store.retrieve(SecretIdentity(service: "ezkey.test.note-save", account: "testuser"))
        XCTAssertEqual(stored.note, "staging token for local tools")
    }

    func testRetrieveReturnsNoteUnmasked() async {
        let identity = SecretIdentity(service: "ezkey.test.note-get", account: "testuser")
        await store.seed(identity, secret: "hidden-value", note: "prod west")
        model.service = identity.service
        model.mode = .retrieve
        await model.retrieve()
        XCTAssertEqual(model.status, .retrieved)
        XCTAssertEqual(model.retrievedSecret, "hidden-value")
        XCTAssertEqual(model.retrievedNote, "prod west")
        XCTAssertFalse(model.isRevealed)
    }

    func testSelectingAMatchRetrievesNote() async {
        let staging = SecretIdentity(service: "myapp/staging/llm", account: "testuser")
        let prod = SecretIdentity(service: "myapp/prod/llm", account: "testuser")
        await store.seed(staging, secret: "staging-secret", note: "staging cluster")
        await store.seed(prod, secret: "prod-secret", note: "prod cluster")
        model.service = "myapp"
        model.mode = .retrieve
        await model.retrieve()
        await model.selectMatch(staging)
        XCTAssertEqual(model.retrievedSecret, "staging-secret")
        XCTAssertEqual(model.retrievedNote, "staging cluster")
    }

    func testSaveExistingPrefillsNoteForUpdate() async {
        let identity = SecretIdentity(service: "ezkey.test.note-prefill", account: "testuser")
        await store.seed(identity, secret: "old", note: "keep this")
        model.service = identity.service
        model.secretToSave = "new"
        await model.save()
        XCTAssertEqual(model.status, .needsUpdate)
        XCTAssertEqual(model.noteToSave, "keep this")
    }

    func testSaveExistingDoesNotOverwriteTypedNote() async {
        let identity = SecretIdentity(service: "ezkey.test.note-typed", account: "testuser")
        await store.seed(identity, secret: "old", note: "old-note")
        model.service = identity.service
        model.secretToSave = "new"
        model.noteToSave = "new-note"
        await model.save()
        XCTAssertEqual(model.status, .needsUpdate)
        XCTAssertEqual(model.noteToSave, "new-note")
    }

    func testUpdateWritesNote() async throws {
        let identity = SecretIdentity(service: "ezkey.test.note-update", account: "testuser")
        await store.seed(identity, secret: "old", note: "old-note")
        model.service = identity.service
        model.secretToSave = "new"
        model.noteToSave = "rotated 2026-09"
        await model.update()
        XCTAssertEqual(model.status, .updated)
        XCTAssertEqual(model.noteToSave, "")
        let stored = try await store.retrieve(identity)
        XCTAssertEqual(stored.secret, "new")
        XCTAssertEqual(stored.note, "rotated 2026-09")
    }

    func testPanelCloseClearsNotes() async {
        model.service = "ezkey.test.close-note"
        model.noteToSave = "draft-note"
        model.retrievedNote = "retrieved-note"
        model.panelDidClose()
        XCTAssertEqual(model.noteToSave, "")
        XCTAssertNil(model.retrievedNote)
    }

    func testModeSwitchCopiesNoteIntoSaveField() async {
        let identity = SecretIdentity(service: "ezkey.test.note-copy", account: "testuser")
        await store.seed(identity, secret: "value", note: "from retrieve")
        model.service = identity.service
        model.mode = .retrieve
        await model.retrieve()
        model.mode = .save
        XCTAssertNil(model.retrievedNote)
        XCTAssertEqual(model.noteToSave, "from retrieve")
    }
}
