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
            if status == .retrieved || status == .copied || status == .needsUpdate {
                status = .idle
            }
        }
    }

    public var service: String {
        didSet { resetNeedsUpdateIfIdentityChanged() }
    }

    public var account: String {
        didSet { resetNeedsUpdateIfIdentityChanged() }
    }

    public var secretToSave: String = ""
    public var retrievedSecret: String?
    public var isRevealed: Bool = false
    public var status: OperationStatus = .idle
    public var isPanelOpen: Bool = false

    @ObservationIgnored
    private let store: any SecretStore
    @ObservationIgnored
    private let clipboard: ClipboardGuard
    @ObservationIgnored
    private let defaults: UserDefaults
    @ObservationIgnored
    private let currentUser: String
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
        let storedAccount = defaults.string(forKey: Self.accountDefaultsKey) ?? ""
        self.account = storedAccount.isEmpty ? currentUser : storedAccount
    }

    public var isWorking: Bool { status == .working }

    public var identity: SecretIdentity {
        SecretIdentity(service: service, account: account)
    }

    public func panelDidOpen() {
        isPanelOpen = true
        if account.isEmpty {
            account = currentUser
        }
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
        isRevealed = false
        status = .idle
        identityAtNeedsUpdate = nil
    }

    public func save() async {
        persistLabels()
        let identity = identity
        guard identity.isValid else {
            status = .validation("Service and account are required.")
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
        let identity = identity
        guard identity.isValid else {
            status = .validation("Service and account are required.")
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
        let identity = identity
        guard identity.isValid else {
            status = .validation("Service and account are required.")
            return
        }
        status = .working
        retrieveGeneration += 1
        let generation = retrieveGeneration
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
        defaults.set(account, forKey: Self.accountDefaultsKey)
    }

    private func resetNeedsUpdateIfIdentityChanged() {
        guard status == .needsUpdate else { return }
        let current = SecretIdentity(service: service, account: account)
        if current != identityAtNeedsUpdate {
            status = .idle
            identityAtNeedsUpdate = nil
        }
    }
}
