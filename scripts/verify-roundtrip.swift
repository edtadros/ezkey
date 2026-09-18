import Foundation
import Security

/// Signed CLI interop checks against login.keychain-db.
/// Never prints secret values. Only mutates ezkey.test.* entries.

let loginPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Keychains/login.keychain-db")
    .path
let account = NSUserName()
var created: [String] = []
var failures = 0

func fail(_ name: String, _ detail: String) {
    failures += 1
    fputs("FAIL \(name) \(detail)\n", stderr)
}

func pass(_ name: String) {
    print("PASS \(name)")
}

func cleanup() {
    for service in created {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["delete-generic-password", "-a", account, "-s", service, loginPath]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }
}

func openLogin() throws -> SecKeychain {
    var keychain: SecKeychain?
    let status = SecKeychainOpen(loginPath, &keychain)
    guard status == errSecSuccess, let keychain else {
        throw NSError(domain: "ezkey.verify", code: Int(status))
    }
    return keychain
}

func makeAccess() -> SecAccess? {
    var trustedSelf: SecTrustedApplication?
    var trustedCLI: SecTrustedApplication?
    guard SecTrustedApplicationCreateFromPath(nil, &trustedSelf) == errSecSuccess,
          let trustedSelf,
          SecTrustedApplicationCreateFromPath("/usr/bin/security", &trustedCLI) == errSecSuccess,
          let trustedCLI
    else { return nil }
    var access: SecAccess?
    let status = SecAccessCreate("ezkey" as CFString, [trustedSelf, trustedCLI] as CFArray, &access)
    return status == errSecSuccess ? access : nil
}

func addViaSecItem(service: String, secret: String) -> OSStatus {
    guard let keychain = try? openLogin() else { return errSecParam }
    var query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecValueData: Data(secret.utf8),
        kSecUseKeychain: keychain,
        kSecUseDataProtectionKeychain: false
    ]
    if let access = makeAccess() {
        query[kSecAttrAccess] = access
    }
    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecSuccess { created.append(service) }
    return status
}

func findViaSecItem(service: String) -> (OSStatus, String?) {
    guard let keychain = try? openLogin() else { return (errSecParam, nil) }
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
        kSecMatchSearchList: [keychain],
        kSecUseDataProtectionKeychain: false
    ]
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else { return (status, nil) }
    return (status, String(data: data, encoding: .utf8))
}

func updateViaSecItem(service: String, secret: String) -> OSStatus {
    guard let keychain = try? openLogin() else { return errSecParam }
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecMatchSearchList: [keychain],
        kSecUseDataProtectionKeychain: false
    ]
    let attrs: [CFString: Any] = [kSecValueData: Data(secret.utf8)]
    return SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
}

func runSecurity(_ arguments: [String], timeout: TimeInterval = 10) -> (Int32, String) {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    proc.arguments = arguments
    let out = Pipe()
    proc.standardOutput = out
    proc.standardError = FileHandle.nullDevice
    let group = DispatchGroup()
    group.enter()
    proc.terminationHandler = { _ in group.leave() }
    do { try proc.run() } catch { return (-1, "") }
    if group.wait(timeout: .now() + timeout) == .timedOut {
        proc.terminate()
        return (-2, "")
    }
    let text = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (proc.terminationStatus, text.trimmingCharacters(in: .newlines))
}

func securityAdd(service: String, secret: String) -> Int32 {
    let (code, _) = runSecurity([
        "add-generic-password", "-U", "-A",
        "-a", account, "-s", service, "-w", secret, loginPath
    ])
    if code == 0 { created.append(service) }
    return code
}

func securityFind(service: String) -> (Int32, String) {
    runSecurity([
        "find-generic-password", "-a", account, "-s", service, "-w", loginPath
    ])
}

let runID = String(UUID().uuidString.prefix(8))
print("verify-roundtrip run=\(runID) account=\(account)")

do {
    let service = "ezkey.test.verify.\(runID).cli"
    let secret = "cli-into-ezkey \(runID) \"quotes\" café"
    let addCode = securityAdd(service: service, secret: secret)
    let (status, value) = findViaSecItem(service: service)
    if addCode == 0, status == errSecSuccess, value == secret {
        pass("cli-add-secitem-find")
    } else {
        fail("cli-add-secitem-find", "add=\(addCode) status=\(status)")
    }
}

do {
    let service = "ezkey.test.verify.\(runID).app"
    let secret = "  ezkey-into-cli \(runID) αβγ 🔑 "
    let addStatus = addViaSecItem(service: service, secret: secret)
    let (code, value) = securityFind(service: service)
    if addStatus == errSecSuccess, code == 0, value == secret {
        pass("secitem-add-cli-find")
    } else {
        fail("secitem-add-cli-find", "add=\(addStatus) cli=\(code)")
    }
}

do {
    let keep = "ezkey.test.verify.\(runID).keep"
    let change = "ezkey.test.verify.\(runID).change"
    _ = addViaSecItem(service: keep, secret: "untouched")
    _ = addViaSecItem(service: change, secret: "before")
    let updateStatus = updateViaSecItem(service: change, secret: "after")
    let (keepStatus, keepValue) = findViaSecItem(service: keep)
    let (changeStatus, changeValue) = findViaSecItem(service: change)
    if updateStatus == errSecSuccess,
       keepStatus == errSecSuccess, keepValue == "untouched",
       changeStatus == errSecSuccess, changeValue == "after" {
        pass("update-does-not-clobber-other-pair")
    } else {
        fail("update-does-not-clobber-other-pair", "update=\(updateStatus)")
    }
}

do {
    let service = "ezkey.test.verify.\(runID).missing"
    let (status, _) = findViaSecItem(service: service)
    if status == errSecItemNotFound {
        pass("missing-entry")
    } else {
        fail("missing-entry", "status=\(status)")
    }
}

cleanup()
if failures > 0 {
    fputs("\(failures) failure(s)\n", stderr)
    exit(1)
}
print("all round-trip checks passed")
