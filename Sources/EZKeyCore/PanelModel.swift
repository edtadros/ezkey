import Foundation
import Observation

@MainActor
@Observable
public final class PanelModel {
    public var mode: PanelMode = .save {
        didSet {
            guard oldValue != mode else { return }
            clearRetrieved()
            matches = []
            if status == .retrieved || status == .copied || status == .updated || status == .alreadyExists || status == .chooseMatch || status.isUpdateHint {
                status = .idle
            }
        }
    }

    public var service: String {
        didSet {
            guard oldValue != service else { return }
            if status == .alreadyExists { status = .idle }
            resetMatchesIfSearchChanged()
        }
    }

    public var account: String {
        didSet {
            guard oldValue != account else { return }
            resetMatchesIfSearchChanged()
        }
    }

    public var secretToSave: String = ""
    public var noteToSave: String = ""
    public var retrievedSecret: String?
    public var retrievedNote: String?
    /// The entry whose secret is on screen. Update always targets this, never
    /// whatever is typed in Name afterwards.
    public var retrievedIdentity: SecretIdentity?
    /// Present while the Update section is open.
    public var pendingUpdate: PendingUpdate?
    public var matches: [SecretIdentity] = []
    public var isRevealed: Bool = false
    public var status: OperationStatus = .idle
    public var isPanelOpen: Bool = false

    @ObservationIgnored
    private let store: any SecretStore
    @ObservationIgnored
    private let clipboard: ClipboardGuard
    @ObservationIgnored
    private let defaults: UserDefaults
    public let currentUser: String
    @ObservationIgnored
    private var retrieveGeneration = 0
    /// Invoked when a Keychain operation finishes after the menu-bar panel
    /// was dismissed (typical when the system password dialog steals focus).
    @ObservationIgnored
    public var onOperationFinishedWhileClosed: (@MainActor () -> Void)?

    public static let serviceDefaultsKey = "ezkey.service"
    public static let accountDefaultsKey = "ezkey.account"

    public init(
        store: any SecretStore = LoginKeychainStore(),
        clipboard: ClipboardGuard? = nil,
        defaults: UserDefaults = .standard,
        currentUser: String = NSUserName()
    ) {
        self.store = store
        self.clipboard = clipboard ?? ClipboardGuard()
        self.defaults = defaults
        self.currentUser = currentUser
        self.service = defaults.string(forKey: Self.serviceDefaultsKey) ?? ""
        self.account = currentUser
    }

    public var isWorking: Bool { status == .working }

    public var identity: SecretIdentity {
        SecretIdentity(service: service, account: currentUser)
    }

    public func panelDidOpen() {
        isPanelOpen = true
        account = currentUser
    }

    public func panelDidClose() {
        guard isPanelOpen else { return }
        isPanelOpen = false
        persistLabels()
        if isWorking {
            return
        }
        retrieveGeneration += 1
        secretToSave = ""
        noteToSave = ""
        clearRetrieved()
        matches = []
        status = .idle
    }

    /// The Return key. Replacing a secret takes a click on Replace, so Return
    /// never replaces anything, and does nothing while Update is open.
    public func submit() async {
        guard pendingUpdate == nil else {
            nudgeTowardUpdate()
            return
        }
        if mode == .save {
            await save()
        } else {
            await retrieve()
        }
    }

    public func save() async {
        persistLabels()
        account = currentUser
        let identity = identity
        guard identity.isValid else {
            status = .validation("Name is required.")
            return
        }
        guard !secretToSave.isEmpty else {
            status = .validation("Enter a secret to save.")
            return
        }
        status = .working
        do {
            if try await store.contains(identity) {
                status = .alreadyExists
                noteFinishedWhileClosed()
                return
            }
            try await store.add(identity, secret: secretToSave, note: StoredSecret.normalizedNote(noteToSave))
            secretToSave = ""
            noteToSave = ""
            status = .saved
            noteFinishedWhileClosed()
        } catch let error as KeychainError {
            status = .from(error: error)
            noteFinishedWhileClosed()
        } catch {
            status = .failure
            noteFinishedWhileClosed()
        }
    }

    /// What Replace would change, for the Update section. Secrets are compared,
    /// never shown.
    public var updateSummary: UpdateSummary? {
        guard let pendingUpdate, let retrievedSecret else { return nil }
        return UpdateSummary(
            currentSecret: retrievedSecret,
            currentNote: retrievedNote ?? "",
            pending: pendingUpdate
        )
    }

    /// Someone tried to edit the read-only secret, or pressed Return inside
    /// Update. Point at the button that does it instead of doing nothing.
    public func nudgeTowardUpdate() {
        guard retrievedSecret != nil, !isWorking else { return }
        status = pendingUpdate == nil ? .clickUpdateToChange : .clickReplaceToUpdate
    }

    public func beginUpdate() {
        guard retrievedSecret != nil, retrievedIdentity != nil else { return }
        pendingUpdate = PendingUpdate(secret: "", note: retrievedNote ?? "")
        isRevealed = false
        if status.isUpdateHint { status = .retrieved }
    }

    public func cancelUpdate() {
        pendingUpdate = nil
        if status.isUpdateHint { status = .retrieved }
    }

    /// Replaces the retrieved entry. The store asks for the login password
    /// first; the old secret cannot be recovered afterwards.
    public func replaceRetrieved() async {
        guard let identity = retrievedIdentity,
              let summary = updateSummary,
              summary.hasChanges
        else { return }
        status = .working
        do {
            try await store.update(identity, secret: summary.newSecret, note: summary.newNote)
            retrievedSecret = summary.newSecret
            retrievedNote = summary.newNote
            pendingUpdate = nil
            isRevealed = false
            status = .updated
        } catch let error as KeychainError {
            status = .from(error: error)
        } catch {
            status = .failure
        }
        noteFinishedWhileClosed()
    }

    public func retrieve() async {
        persistLabels()
        clearRetrieved()
        matches = []
        let query = service.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            status = .validation("Enter a name to search.")
            return
        }
        status = .working
        retrieveGeneration += 1
        let generation = retrieveGeneration
        do {
            let owned = SecretIdentity(service: query, account: currentUser)
            if owned.isValid, try await store.contains(owned) {
                await fetchSecret(owned, generation: generation)
                return
            }
            let found = try await store.list(matching: query)
            guard generation == retrieveGeneration else { return }
            if found.isEmpty {
                status = .noMatches
                noteFinishedWhileClosed()
                return
            }
            matches = found
            status = .chooseMatch
            noteFinishedWhileClosed()
        } catch let error as KeychainError {
            applyRetrieveResult(.failure(error), identity: nil, generation: generation)
        } catch {
            guard generation == retrieveGeneration else { return }
            clearRetrieved()
            status = .failure
            noteFinishedWhileClosed()
        }
    }

    public func selectMatch(_ identity: SecretIdentity) async {
        matches = []
        service = identity.service
        account = identity.account
        persistLabels()
        clearRetrieved()
        status = .working
        retrieveGeneration += 1
        await fetchSecret(identity, generation: retrieveGeneration)
    }

    private func fetchSecret(_ identity: SecretIdentity, generation: Int) async {
        do {
            let stored = try await store.retrieve(identity)
            applyRetrieveResult(.success(stored), identity: identity, generation: generation)
        } catch let error as KeychainError {
            applyRetrieveResult(.failure(error), identity: identity, generation: generation)
        } catch {
            guard generation == retrieveGeneration else { return }
            clearRetrieved()
            status = .failure
            noteFinishedWhileClosed()
        }
    }

    public func toggleReveal() {
        guard retrievedSecret != nil else { return }
        isRevealed.toggle()
    }

    public func copyRetrieved() {
        guard let retrievedSecret else { return }
        clipboard.copy(retrievedSecret)
        status = .copied
    }

    private func applyRetrieveResult(
        _ result: Result<StoredSecret, KeychainError>,
        identity: SecretIdentity?,
        generation: Int
    ) {
        guard generation == retrieveGeneration else { return }
        clearRetrieved()
        switch result {
        case .success(let stored):
            retrievedSecret = stored.secret
            retrievedNote = stored.note
            retrievedIdentity = identity
            status = .retrieved
        case .failure(let error):
            status = .from(error: error)
        }
        noteFinishedWhileClosed()
    }

    private func noteFinishedWhileClosed() {
        guard !isPanelOpen else { return }
        onOperationFinishedWhileClosed?()
    }

    private func persistLabels() {
        defaults.set(service, forKey: Self.serviceDefaultsKey)
        defaults.set(currentUser, forKey: Self.accountDefaultsKey)
    }

    private func clearRetrieved() {
        retrievedSecret = nil
        retrievedNote = nil
        retrievedIdentity = nil
        pendingUpdate = nil
        isRevealed = false
    }

    private func resetMatchesIfSearchChanged() {
        guard !matches.isEmpty else { return }
        matches = []
        if status == .chooseMatch {
            status = .idle
        }
    }
}
