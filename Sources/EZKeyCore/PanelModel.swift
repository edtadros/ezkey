import Foundation
import Observation

@MainActor
@Observable
public final class PanelModel {
    public var mode: PanelMode = .save {
        didSet {
            guard oldValue != mode else { return }
            retrievedSecret = nil
            isRevealed = false
            matches = []
            if status == .retrieved || status == .copied || status == .needsUpdate || status == .chooseMatch {
                status = .idle
            }
        }
    }

    public var service: String {
        didSet {
            resetNeedsUpdateIfIdentityChanged()
            resetMatchesIfSearchChanged()
        }
    }

    public var account: String {
        didSet {
            resetNeedsUpdateIfIdentityChanged()
            resetMatchesIfSearchChanged()
        }
    }

    public var secretToSave: String = ""
    public var retrievedSecret: String?
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
    @ObservationIgnored
    private var identityAtNeedsUpdate: SecretIdentity?
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
        retrievedSecret = nil
        matches = []
        isRevealed = false
        status = .idle
        identityAtNeedsUpdate = nil
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
                identityAtNeedsUpdate = identity
                status = .needsUpdate
                noteFinishedWhileClosed()
                return
            }
            try await store.add(identity, secret: secretToSave)
            secretToSave = ""
            identityAtNeedsUpdate = nil
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

    public func update() async {
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
            try await store.update(identity, secret: secretToSave)
            secretToSave = ""
            identityAtNeedsUpdate = nil
            status = .updated
            noteFinishedWhileClosed()
        } catch let error as KeychainError {
            status = .from(error: error)
            noteFinishedWhileClosed()
        } catch {
            status = .failure
            noteFinishedWhileClosed()
        }
    }

    public func retrieve() async {
        persistLabels()
        retrievedSecret = nil
        isRevealed = false
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
            applyRetrieveResult(.failure(error), generation: generation)
        } catch {
            guard generation == retrieveGeneration else { return }
            retrievedSecret = nil
            isRevealed = false
            status = .failure
            noteFinishedWhileClosed()
        }
    }

    public func selectMatch(_ identity: SecretIdentity) async {
        matches = []
        service = identity.service
        account = identity.account
        persistLabels()
        retrievedSecret = nil
        isRevealed = false
        status = .working
        retrieveGeneration += 1
        await fetchSecret(identity, generation: retrieveGeneration)
    }

    private func fetchSecret(_ identity: SecretIdentity, generation: Int) async {
        do {
            let secret = try await store.retrieve(identity)
            applyRetrieveResult(.success(secret), generation: generation)
        } catch let error as KeychainError {
            applyRetrieveResult(.failure(error), generation: generation)
        } catch {
            guard generation == retrieveGeneration else { return }
            retrievedSecret = nil
            isRevealed = false
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

    private func applyRetrieveResult(_ result: Result<String, KeychainError>, generation: Int) {
        guard generation == retrieveGeneration else { return }
        switch result {
        case .success(let secret):
            retrievedSecret = secret
            isRevealed = false
            status = .retrieved
        case .failure(let error):
            retrievedSecret = nil
            isRevealed = false
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

    private func resetNeedsUpdateIfIdentityChanged() {
        guard status == .needsUpdate else { return }
        let current = SecretIdentity(service: service, account: account)
        if current != identityAtNeedsUpdate {
            status = .idle
            identityAtNeedsUpdate = nil
        }
    }

    private func resetMatchesIfSearchChanged() {
        guard !matches.isEmpty else { return }
        matches = []
        if status == .chooseMatch {
            status = .idle
        }
    }
}
