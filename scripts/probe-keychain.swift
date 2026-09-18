import Foundation
import Security

/// Probe which Security.framework query shapes land in login.keychain-db
/// so they are visible to `/usr/bin/security find-generic-password`.
/// Prints PASS/FAIL only. Never prints secret values.

let loginPath = NSHomeDirectory() + "/Library/Keychains/login.keychain-db"
let account = NSUserName()
let runID = String(UUID().uuidString.prefix(8))
var createdServices: [String] = []

func failAndExit(_ message: String) -> Never {
    fputs("FAIL \(message)\n", stderr)
    cleanup()
    exit(1)
}

func cleanup() {
    for service in createdServices {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = [
            "delete-generic-password",
            "-a", account,
            "-s", service,
            loginPath
        ]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }
}

func openLoginKeychain() -> SecKeychain {
    var keychain: SecKeychain?
    let status = SecKeychainOpen(loginPath, &keychain)
    guard status == errSecSuccess, let keychain else {
        failAndExit("SecKeychainOpen status=\(status)")
    }
    return keychain
}

func securityFind(service: String) -> (exitCode: Int32, found: Bool, matches: Bool, secret: String?) {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    proc.arguments = [
        "find-generic-password",
        "-a", account,
        "-s", service,
        "-w",
        loginPath
    ]
    let out = Pipe()
    let err = Pipe()
    proc.standardOutput = out
    proc.standardError = err
    do {
        try proc.run()
    } catch {
        failAndExit("failed to spawn security: \(error)")
    }
    proc.waitUntilExit()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    let text = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .newlines)
    let found = proc.terminationStatus == 0 && text != nil && !(text ?? "").isEmpty
    return (proc.terminationStatus, found, false, text)
}

func securityAdd(service: String, secret: String) -> Int32 {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    proc.arguments = [
        "add-generic-password",
        "-U",
        "-A",
        "-a", account,
        "-s", service,
        "-w", secret,
        loginPath
    ]
    proc.standardOutput = FileHandle.nullDevice
    proc.standardError = FileHandle.nullDevice
    do {
        try proc.run()
    } catch {
        failAndExit("failed to spawn security add: \(error)")
    }
    proc.waitUntilExit()
    createdServices.append(service)
    return proc.terminationStatus
}

func addViaSecItem(service: String, secret: String, queryMutator: (inout [CFString: Any]) -> Void) -> OSStatus {
    guard let data = secret.data(using: .utf8) else {
        failAndExit("utf8 encode failed")
    }
    var query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecValueData: data
    ]
    queryMutator(&query)
    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecSuccess {
        createdServices.append(service)
    }
    return status
}

func findViaSecItem(service: String, queryMutator: (inout [CFString: Any]) -> Void) -> (OSStatus, String?) {
    var query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne
    ]
    queryMutator(&query)
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else { return (status, nil) }
    guard let data = result as? Data else { return (status, nil) }
    return (status, String(data: data, encoding: .utf8))
}

func report(_ name: String, _ passed: Bool, _ detail: String) {
    print("\(passed ? "PASS" : "FAIL") \(name) \(detail)")
}

print("probe run=\(runID) account=\(account) keychain=\(loginPath)")

let keychain = openLoginKeychain()
print("opened login keychain")

// 1. Naive SecItemAdd (no keychain targeting)
do {
    let service = "ezkey.test.probe.\(runID).naive"
    let secret = "naive-secret-\(runID)"
    let addStatus = addViaSecItem(service: service, secret: secret) { _ in }
    let cli = securityFind(service: service)
    let visible = cli.found && cli.secret == secret
    report(
        "naive-secitem-add-visible-to-security-cli",
        visible,
        "addStatus=\(addStatus) cliExit=\(cli.exitCode) visible=\(visible)"
    )
}

// 2. kSecUseDataProtectionKeychain = false only
do {
    let service = "ezkey.test.probe.\(runID).nodp"
    let secret = "nodp-secret-\(runID)"
    let addStatus = addViaSecItem(service: service, secret: secret) { query in
        query[kSecUseDataProtectionKeychain] = false
    }
    let cli = securityFind(service: service)
    let visible = cli.found && cli.secret == secret
    report(
        "nodp-secitem-add-visible-to-security-cli",
        visible,
        "addStatus=\(addStatus) cliExit=\(cli.exitCode) visible=\(visible)"
    )
}

// 3. kSecUseKeychain = login
do {
    let service = "ezkey.test.probe.\(runID).usekc"
    let secret = "usekc-secret-\(runID)"
    let addStatus = addViaSecItem(service: service, secret: secret) { query in
        query[kSecUseKeychain] = keychain
    }
    let cli = securityFind(service: service)
    let visible = cli.found && cli.secret == secret
    report(
        "usekeychain-secitem-add-visible-to-security-cli",
        visible,
        "addStatus=\(addStatus) cliExit=\(cli.exitCode) visible=\(visible)"
    )
}

// 4. kSecUseKeychain + kSecUseDataProtectionKeychain false
do {
    let service = "ezkey.test.probe.\(runID).both"
    let secret = "both-secret-\(runID)"
    let addStatus = addViaSecItem(service: service, secret: secret) { query in
        query[kSecUseKeychain] = keychain
        query[kSecUseDataProtectionKeychain] = false
    }
    let cli = securityFind(service: service)
    let visible = cli.found && cli.secret == secret
    report(
        "both-flags-secitem-add-visible-to-security-cli",
        visible,
        "addStatus=\(addStatus) cliExit=\(cli.exitCode) visible=\(visible)"
    )
}

// 5. CLI add, then SecItemCopyMatching with search list
do {
    let service = "ezkey.test.probe.\(runID).cli"
    let secret = "cli-secret-\(runID)- space -\"quotes\"-αβγ-🔑"
    let addExit = securityAdd(service: service, secret: secret)
    let (statusDefault, valueDefault) = findViaSecItem(service: service) { _ in }
    let (statusSearch, valueSearch) = findViaSecItem(service: service) { query in
        query[kSecMatchSearchList] = [keychain]
        query[kSecUseDataProtectionKeychain] = false
    }
    let defaultOK = statusDefault == errSecSuccess && valueDefault == secret
    let searchOK = statusSearch == errSecSuccess && valueSearch == secret
    report(
        "cli-add-default-secitem-find",
        defaultOK,
        "addExit=\(addExit) status=\(statusDefault) match=\(defaultOK)"
    )
    report(
        "cli-add-searchlist-secitem-find",
        searchOK,
        "addExit=\(addExit) status=\(statusSearch) match=\(searchOK)"
    )
}

cleanup()
print("cleanup done")
