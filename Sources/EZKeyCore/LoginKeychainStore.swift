import Foundation
import Security

public protocol SecretStore: Sendable {
    func contains(_ identity: SecretIdentity) async throws -> Bool
    func add(_ identity: SecretIdentity, secret: String, note: String) async throws
    func update(_ identity: SecretIdentity, secret: String, note: String) async throws
    func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret
    func comment(for identity: SecretIdentity) async throws -> String
    func list(matching query: String) async throws -> [SecretIdentity]
    func delete(_ identity: SecretIdentity) async throws
}

/// Generic-password access to the user's file-based login Keychain.
///
/// SecItem's default data-protection store is a different database than
/// `~/Library/Keychains/login.keychain-db`. This type opens that file
/// explicitly so items round-trip with `/usr/bin/security`.
///
/// File-based Keychain APIs are deprecated by Apple in favor of the data-
/// protection keychain. They remain the correct API for this compatibility
/// requirement.
public actor LoginKeychainStore: SecretStore {
    public let keychainPath: String
    /// When false, Keychain calls fail instead of showing a password dialog.
    /// Tests use this so an unexpected ACL prompt cannot hang the suite.
    public let allowsPrompt: Bool

    public init(
        keychainPath: String = LoginKeychainStore.defaultLoginPath,
        allowsPrompt: Bool = true
    ) {
        self.keychainPath = keychainPath
        self.allowsPrompt = allowsPrompt
    }

    public static var defaultLoginPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Keychains/login.keychain-db")
            .path
    }

    public func contains(_ identity: SecretIdentity) async throws -> Bool {
        try requireValid(identity)
        var result: CFTypeRef?
        let status = SecItemCopyMatching(try searchQuery(identity, returnData: false) as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        case errSecInteractionNotAllowed, errSecAuthFailed:
            // Attributes were gated; the item exists.
            return true
        default:
            throw KeychainError.from(status: status)
        }
    }

    public func add(_ identity: SecretIdentity, secret: String, note: String = "") async throws {
        try requireValid(identity)
        try requireSecret(secret)
        let keychain = try openLoginKeychain()
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: identity.service,
            kSecAttrLabel: identity.service,
            kSecAttrAccount: identity.account,
            kSecValueData: Data(secret.utf8),
            kSecUseKeychain: keychain,
            kSecUseDataProtectionKeychain: false
        ]
        let trimmedNote = StoredSecret.normalizedNote(note)
        if !trimmedNote.isEmpty {
            query[kSecAttrComment] = trimmedNote
        }
        let status = SecItemAdd(query as CFDictionary, nil)
        try check(status)
    }

    public func update(_ identity: SecretIdentity, secret: String, note: String = "") async throws {
        try requireValid(identity)
        try requireSecret(secret)
        var query = try searchQuery(identity, returnData: false)
        query[kSecUseAuthenticationUI] = allowsPrompt
            ? kSecUseAuthenticationUIAllow
            : kSecUseAuthenticationUIFail
        let attributes: [CFString: Any] = [
            kSecValueData: Data(secret.utf8),
            kSecAttrComment: StoredSecret.normalizedNote(note)
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        try check(status)
    }

    public func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret {
        try requireValid(identity)
        var query = try searchQuery(identity, returnData: true)
        query[kSecReturnAttributes] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        try check(status)
        return try storedSecret(from: result)
    }

    public func comment(for identity: SecretIdentity) async throws -> String {
        try requireValid(identity)
        var result: CFTypeRef?
        let status = SecItemCopyMatching(try searchQuery(identity, returnData: false) as CFDictionary, &result)
        try check(status)
        return Self.commentString(from: result)
    }

    public static let matchLimit = 50

    public func list(matching query: String) async throws -> [SecretIdentity] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        let keychain = try openLoginKeychain()
        let search: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecMatchSearchList: [keychain],
            kSecUseDataProtectionKeychain: false,
            kSecReturnAttributes: true,
            kSecReturnData: false,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecUseAuthenticationUI: kSecUseAuthenticationUISkip
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(search as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        try check(status)
        let records: [NSDictionary]
        if let dicts = result as? [NSDictionary] {
            records = dicts
        } else if let array = result as? NSArray {
            records = array.compactMap { $0 as? NSDictionary }
        } else {
            return []
        }
        var seen = Set<SecretIdentity>()
        var matches: [SecretIdentity] = []
        for record in records {
            let service = record[kSecAttrService] as? String ?? ""
            let account = record[kSecAttrAccount] as? String ?? ""
            let label = record[kSecAttrLabel] as? String ?? ""
            let identity = SecretIdentity(service: service, account: account)
            guard identity.isValid else { continue }
            let comment = Self.commentString(from: record)
            let haystack = [identity.service, identity.account, label, comment]
            guard haystack.contains(where: { $0.localizedCaseInsensitiveContains(needle) }) else { continue }
            guard seen.insert(identity).inserted else { continue }
            matches.append(identity)
        }
        matches.sort {
            ($0.service.localizedLowercase, $0.account.localizedLowercase)
                < ($1.service.localizedLowercase, $1.account.localizedLowercase)
        }
        if matches.count > Self.matchLimit {
            return Array(matches.prefix(Self.matchLimit))
        }
        return matches
    }

    public func delete(_ identity: SecretIdentity) async throws {
        try requireValid(identity)
        let status = SecItemDelete(try searchQuery(identity, returnData: false) as CFDictionary)
        if status == errSecItemNotFound {
            return
        }
        try check(status)
    }

    private func storedSecret(from result: CFTypeRef?) throws -> StoredSecret {
        let note = Self.commentString(from: result)
        if let data = result as? Data {
            guard let secret = String(data: data, encoding: .utf8) else {
                throw KeychainError.failure(errSecDecode)
            }
            return StoredSecret(secret: secret, note: note)
        }
        guard let dict = result as? NSDictionary else {
            throw KeychainError.failure(errSecDecode)
        }
        guard let data = dict[kSecValueData] as? Data,
              let secret = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.failure(errSecDecode)
        }
        return StoredSecret(secret: secret, note: note)
    }

    static func commentString(from result: Any?) -> String {
        guard let dict = result as? NSDictionary else { return "" }
        if let text = dict[kSecAttrComment] as? String {
            return text
        }
        if let data = dict[kSecAttrComment] as? Data,
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return ""
    }

    private func requireValid(_ identity: SecretIdentity) throws {
        guard identity.isValid else { throw KeychainError.invalidIdentity }
    }

    private func requireSecret(_ secret: String) throws {
        guard !secret.isEmpty else { throw KeychainError.emptySecret }
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw KeychainError.from(status: status)
        }
    }

    private func searchQuery(_ identity: SecretIdentity, returnData: Bool) throws -> [CFString: Any] {
        let keychain = try openLoginKeychain()
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: identity.service,
            kSecAttrAccount: identity.account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecMatchSearchList: [keychain],
            kSecUseDataProtectionKeychain: false
        ]
        if returnData {
            query[kSecReturnData] = true
            query[kSecUseAuthenticationUI] = allowsPrompt
                ? kSecUseAuthenticationUIAllow
                : kSecUseAuthenticationUIFail
        } else {
            query[kSecReturnData] = false
            query[kSecReturnAttributes] = true
            query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
        }
        return query
    }

    private func openLoginKeychain() throws -> SecKeychain {
        var keychain: SecKeychain?
        let status = SecKeychainOpen(keychainPath, &keychain)
        guard status == errSecSuccess, let keychain else {
            throw KeychainError.from(status: status)
        }
        return keychain
    }
}
