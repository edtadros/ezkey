import Foundation
import Security

/// Identity of a generic-password item in the login Keychain.
/// The pair (service, account) is the lookup key used by both ezkey and
/// `/usr/bin/security find-generic-password`.
public struct SecretIdentity: Hashable, Sendable, Equatable, Identifiable {
    public let service: String
    public let account: String

    public init(service: String, account: String) {
        self.service = service.trimmingCharacters(in: .whitespacesAndNewlines)
        self.account = account.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var id: String { "\(service)\u{1F}\(account)" }

    public var isValid: Bool {
        !service.isEmpty && !account.isEmpty
    }
}

/// Password bytes plus Keychain Access Comments (`kSecAttrComment`,
/// `security add-generic-password -j`). Comments are item attributes, not a
/// second secret.
public struct StoredSecret: Equatable, Sendable {
    public let secret: String
    public let note: String

    public init(secret: String, note: String = "") {
        self.secret = secret
        self.note = note
    }

    public var hasNote: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public static func normalizedNote(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum PanelMode: String, Sendable, Equatable, CaseIterable, Identifiable {
    case save
    case retrieve

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .save: "Save"
        case .retrieve: "Retrieve"
        }
    }
}

public enum KeychainError: Error, Equatable, Sendable {
    case invalidIdentity
    case emptySecret
    case missingEntry
    case duplicateEntry
    case accessDenied
    case cancelled
    case failure(OSStatus)

    public static func from(status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            .missingEntry
        case errSecDuplicateItem:
            .duplicateEntry
        case errSecUserCanceled:
            .cancelled
        case errSecAuthFailed, errSecInteractionNotAllowed, errSecWrPerm:
            .accessDenied
        default:
            .failure(status)
        }
    }
}

public enum OperationStatus: Equatable, Sendable {
    case idle
    case working
    case saved
    case updated
    case alreadyExists
    case retrieved
    case copied
    case chooseMatch
    case missingEntry
    case noMatches
    case accessDenied
    case cancelled
    case failure
    case validation(String)

    public var message: String {
        switch self {
        case .idle:
            ""
        case .working:
            "Working…"
        case .saved:
            "Saved."
        case .updated:
            "Updated."
        case .alreadyExists:
            "This name already exists. To change it, retrieve it and click Update."
        case .retrieved:
            "Retrieved."
        case .chooseMatch:
            "Select a matching entry."
        case .copied:
            "Copied. Clipboard clears in 30 seconds if unchanged."
        case .missingEntry:
            "No entry for this name and account."
        case .noMatches:
            "No Keychain entries match that name."
        case .accessDenied:
            "Keychain access denied."
        case .cancelled:
            "Keychain access cancelled."
        case .failure:
            "Couldn't complete the Keychain operation."
        case .validation(let message):
            message
        }
    }

    public var isError: Bool {
        switch self {
        case .missingEntry, .noMatches, .accessDenied, .cancelled, .failure, .validation:
            true
        default:
            false
        }
    }

    public static func from(error: KeychainError) -> OperationStatus {
        switch error {
        case .invalidIdentity:
            .validation("Name is required.")
        case .emptySecret:
            .validation("Enter a secret to save.")
        case .missingEntry:
            .missingEntry
        case .duplicateEntry:
            .alreadyExists
        case .accessDenied:
            .accessDenied
        case .cancelled:
            .cancelled
        case .failure:
            .failure
        }
    }
}

/// The Update section's edits. An empty secret keeps the current one.
public struct PendingUpdate: Equatable, Sendable {
    public var secret: String
    public var note: String

    public init(secret: String, note: String) {
        self.secret = secret
        self.note = note
    }
}

/// What Replace would do. Secrets are compared, never displayed.
public struct UpdateSummary: Equatable, Sendable {
    public enum SecretChange: Equatable, Sendable {
        case kept
        case replaced
        case sameAsCurrent
    }

    public let secret: SecretChange
    public let newSecret: String
    public let currentNote: String
    public let newNote: String

    public init(currentSecret: String, currentNote: String, pending: PendingUpdate) {
        if pending.secret.isEmpty {
            secret = .kept
            newSecret = currentSecret
        } else if pending.secret == currentSecret {
            secret = .sameAsCurrent
            newSecret = currentSecret
        } else {
            secret = .replaced
            newSecret = pending.secret
        }
        self.currentNote = StoredSecret.normalizedNote(currentNote)
        newNote = StoredSecret.normalizedNote(pending.note)
    }

    public var noteChanged: Bool { newNote != currentNote }
    public var hasChanges: Bool { secret == .replaced || noteChanged }
}

public enum DisposableEntry {
    public static let servicePrefix = "ezkey.test."

    public static func isDisposable(_ identity: SecretIdentity) -> Bool {
        identity.service.hasPrefix(servicePrefix)
    }
}
