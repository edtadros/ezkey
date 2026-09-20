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
    case needsUpdate
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
        case .needsUpdate:
            "An entry already exists. Click Update to replace it."
        case .retrieved:
            "Retrieved."
        case .chooseMatch:
            "Select a matching entry."
        case .copied:
            "Copied. Clipboard clears in 30 seconds if unchanged."
        case .missingEntry:
            "No entry for this service and account."
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
            .validation("Service and account are required.")
        case .emptySecret:
            .validation("Enter a secret to save.")
        case .missingEntry:
            .missingEntry
        case .duplicateEntry:
            .needsUpdate
        case .accessDenied:
            .accessDenied
        case .cancelled:
            .cancelled
        case .failure:
            .failure
        }
    }
}

public enum DisposableEntry {
    public static let servicePrefix = "ezkey.test."

    public static func isDisposable(_ identity: SecretIdentity) -> Bool {
        identity.service.hasPrefix(servicePrefix)
    }
}
