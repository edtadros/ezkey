_Research snapshot taken 2026-10-27 against ezkey @ a9b4de1 (before the signing work). Facts may be out of date; check the current source._

# ezkey: facts for an iCloud Keychain toggle

Collected on the maintainer's Mac by Outsrc, read-only, ezkey @ a9b4de10e2b844791281988eb24f778970e579f9

- Engine: **direct reads** (git ls-files, cat, sed, git grep). Codex/outsrc was not used: `outsrc list_repos --caller outsrc-bot --json` lists 21 repos, and ezkey is not one of them. I did not register it or change any outsrc settings.
- HEAD: `a9b4de1 feat: eye icon on every secret field; typed secrets visible` (2026-09-28 21:26 PDT). `git status --short` shows only the untracked `.claude/` and `CLAUDE.md`, which I did not open.
- No edits, builds, tests, app launches, or keychain reads were done. The only git commands run were `git log -1`, `git status --short`, `git ls-files`, and `git grep` (read-only).
- Cites are `path:line` at that SHA.

## TL;DR for the iCloud toggle
- Each item is a **file-based login-keychain generic password**. The code opens `~/Library/Keychains/login.keychain-db` with `SecKeychainOpen`, and every query sets `kSecUseDataProtectionKeychain: false` (LoginKeychainStore.swift:14-22, 76-84, 241-250, 294-301). The file-based keychain cannot sync, so iCloud Keychain (`kSecAttrSynchronizable`) needs the **data-protection keychain**, which is a different database.
- Items carry **no ezkey marker**. Service is the literal name the user types, Label equals Service, Account is `NSUserName()`, and Comment holds the note. There is no Description, Generic, Creator, or Type code, and no service prefix except `ezkey.test.` for test items (Models.swift:214-220).
- Listing runs `kSecMatchLimitAll` over **every** generic password in login.keychain-db and filters client-side by substring (LoginKeychainStore.swift:136-185). There is no index file. UserDefaults holds only the last typed name (PanelModel.swift:61-62, 301-304).
- "Ask every time" uses a legacy **SecAccess ACL**: `SecAccessCreate`, then the decrypt ACL's trusted-app list is emptied (LoginKeychainStore.swift:273-292). It does not use LAContext, SecAccessControl, or userPresence. None of `LocalAuthentication`, `SecAccessControl`, `kSecAttrAccessible`, `kSecAttrSynchronizable`, or `kSecAttrAccessGroup` appears anywhere in Sources/, Tests/, or scripts/.
- Platform: macOS 14 only (Package.swift:6-8, Info.plist:25-26). There is no iOS target, no Xcode project, and no .entitlements file. The app is ad-hoc signed by default (build-and-run.sh:39-45).

## 1. Tree, packaging, build/sign/release

### Tracked files under Sources/ and Tests/ (git ls-files)
```
Sources/
├── EZKeyCore/                       (library target)
│   ├── ClipboardGuard.swift          87 lines
│   ├── LoginKeychainStore.swift     302 lines
│   ├── Models.swift                 220 lines
│   └── PanelModel.swift             321 lines
└── ezkey/                           (executable target: menu-bar app)
    ├── EZKeyApp.swift               111 lines
    ├── EZKeyMain.swift              219 lines  (SelfTest, --self-test)
    ├── LoginItem.swift
    ├── MarketingRender.swift        203 lines
    └── PanelView.swift              515 lines
Tests/
├── EZKeyCoreTests/
│   ├── ClipboardGuardTests.swift
│   ├── LoginKeychainStoreTests.swift 230 lines
│   ├── ModelsTests.swift
│   ├── PanelModelTests.swift        562 lines
│   └── SystemPasteboardTests.swift
└── site/review-checklist.test.ts
tests/site/  (lowercase. This is the same folder on case-insensitive APFS, tracked under two casings)
    ├── public-repo.test.ts
    └── worker.test.ts
```
Other relevant tracked files: `Package.swift`, `Resources/Info.plist`, `Resources/AppIcon.icns`, `Resources/MenuBarIcon{,@2x}.png`, `scripts/{build-and-run.sh, install.sh, render-marketing.sh, probe-keychain.swift, verify-roundtrip.swift, scan-public.sh, render_guides.py}`, `.github/workflows/ci.yml`, `RELEASING.md`. Everything else (`site/`, `src/*.ts`, `wrangler.jsonc`, `package.json`) is the Cloudflare marketing site.

**Missing:** no `*.xcodeproj`, `*.xcworkspace`, `*.entitlements`, or Makefile is tracked or present at the repo root. The only plist is `Resources/Info.plist`. Signing is plain `codesign` in build-and-run.sh, with no entitlements file and no keychain-access-groups, so a data-protection/iCloud keychain would require adding entitlements and real Team ID signing.

### Package.swift (full)
```swift
   1  // swift-tools-version: 6.1
   2  import PackageDescription
   3  
   4  let package = Package(
   5      name: "ezkey",
   6      platforms: [
   7          .macOS(.v14),
   8      ],
   9      products: [
  10          .executable(name: "ezkey", targets: ["ezkey"]),
  11          .library(name: "EZKeyCore", targets: ["EZKeyCore"]),
  12      ],
  13      targets: [
  14          .target(
  15              name: "EZKeyCore",
  16              linkerSettings: [
  17                  .linkedFramework("AppKit"),
  18                  .linkedFramework("Security"),
  19              ]
  20          ),
  21          .executableTarget(
  22              name: "ezkey",
  23              dependencies: ["EZKeyCore"],
  24              linkerSettings: [
  25                  .linkedFramework("ServiceManagement"),
  26              ]
  27          ),
  28          .testTarget(
  29              name: "EZKeyCoreTests",
  30              dependencies: ["EZKeyCore"]
  31          ),
  32      ]
  33  )
```

### Resources/Info.plist (full)
```xml
   1  <?xml version="1.0" encoding="UTF-8"?>
   2  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   3  <plist version="1.0">
   4  <dict>
   5    <key>CFBundleDevelopmentRegion</key>
   6    <string>en</string>
   7    <key>CFBundleDisplayName</key>
   8    <string>ezkey</string>
   9    <key>CFBundleExecutable</key>
  10    <string>ezkey</string>
  11    <key>CFBundleIconFile</key>
  12    <string>AppIcon</string>
  13    <key>CFBundleIdentifier</key>
  14    <string>app.ezkey</string>
  15    <key>CFBundleInfoDictionaryVersion</key>
  16    <string>6.0</string>
  17    <key>CFBundleName</key>
  18    <string>ezkey</string>
  19    <key>CFBundlePackageType</key>
  20    <string>APPL</string>
  21    <key>CFBundleShortVersionString</key>
  22    <string>1.0.2</string>
  23    <key>CFBundleVersion</key>
  24    <string>1</string>
  25    <key>LSMinimumSystemVersion</key>
  26    <string>14.0</string>
  27    <key>LSUIElement</key>
  28    <true/>
  29    <key>NSHighResolutionCapable</key>
  30    <true/>
  31    <key>NSHumanReadableCopyright</key>
  32    <string>Copyright 2026 ezkey authors. Provided as-is, without warranty.</string>
  33    <key>NSPrincipalClass</key>
  34    <string>NSApplication</string>
  35  </dict>
  36  </plist>
```

### scripts/build-and-run.sh (full). This is the only build/sign script.
```sh
   1  #!/bin/zsh
   2  set -euo pipefail
   3  
   4  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
   5  APP_NAME="ezkey"
   6  BUNDLE_ID="app.ezkey"
   7  BUILD_ROOT="$ROOT_DIR/build"
   8  APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
   9  EXECUTABLE_PATH="$ROOT_DIR/.build/release/${APP_NAME}"
  10  INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
  11  LICENSE_FILE="$ROOT_DIR/LICENSE"
  12  # Optional: sign with a local identity instead of ad-hoc.
  13  SIGN_IDENTITY="${EZKEY_SIGN_IDENTITY:-}"
  14  
  15  cd "$ROOT_DIR"
  16  
  17  if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  18    echo "Running tests…"
  19    swift test --package-path "$ROOT_DIR"
  20  fi
  21  
  22  echo "Building release binary…"
  23  swift build -c release --package-path "$ROOT_DIR"
  24  
  25  echo "Packaging ${APP_NAME}.app…"
  26  rm -rf "$APP_DIR"
  27  mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
  28  cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/${APP_NAME}"
  29  cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
  30  cp "$LICENSE_FILE" "$APP_DIR/Contents/Resources/LICENSE"
  31  for icon in MenuBarIcon.png "MenuBarIcon@2x.png" AppIcon.icns; do
  32    if [[ -f "$ROOT_DIR/Resources/$icon" ]]; then
  33      cp "$ROOT_DIR/Resources/$icon" "$APP_DIR/Contents/Resources/$icon"
  34    fi
  35  done
  36  printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"
  37  xattr -cr "$APP_DIR" >/dev/null 2>&1 || true
  38  
  39  if [[ -n "$SIGN_IDENTITY" ]]; then
  40    codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_DIR"
  41    echo "Signed with $SIGN_IDENTITY"
  42  else
  43    codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_DIR"
  44    echo "Ad-hoc signed for local use. Do not distribute this binary."
  45  fi
  46  
  47  echo "Packaged app: $APP_DIR"
  48  
  49  if [[ "${SKIP_VERIFY:-0}" != "1" ]]; then
  50    echo "Running signed-app Keychain self-test…"
  51    "$APP_DIR/Contents/MacOS/${APP_NAME}" --self-test
  52  fi
  53  
  54  if [[ "${SKIP_INSTALL:-0}" != "1" ]]; then
  55    INSTALL_DIR="${EZKEY_INSTALL_DIR:-/Applications}"
  56    mkdir -p "$INSTALL_DIR"
  57    INSTALLED="$INSTALL_DIR/${APP_NAME}.app"
  58    rm -rf "$INSTALLED"
  59    ditto "$APP_DIR" "$INSTALLED"
  60    if [[ -n "$SIGN_IDENTITY" ]]; then
  61      codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$INSTALLED"
  62    else
  63      codesign --force --sign - --identifier "$BUNDLE_ID" "$INSTALLED"
  64    fi
  65    echo "Installed: $INSTALLED"
  66    if [[ "$INSTALLED" == "/Applications/${APP_NAME}.app" && -d "$HOME/Applications/${APP_NAME}.app" ]]; then
  67      rm -rf "$HOME/Applications/${APP_NAME}.app"
  68      echo "Removed the earlier copy in ~/Applications."
  69    fi
  70  
  71    if [[ "${SKIP_LAUNCH:-0}" != "1" ]]; then
  72      pkill -x ezkey >/dev/null 2>&1 || true
  73      open "$INSTALLED"
  74      echo "Opened ${INSTALLED}. Open at Login is on unless you turn it off in the panel."
  75    fi
  76  fi
```

### scripts/install.sh (full)
```sh
   1  #!/bin/zsh
   2  # Install ezkey on this Mac.
   3  # Builds from source, copies the app to /Applications/ezkey.app, and opens it.
   4  # The app then registers Open at Login (System Settings → General → Login Items).
   5  set -euo pipefail
   6  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
   7  exec "$ROOT_DIR/scripts/build-and-run.sh"
```

### scripts/render-marketing.sh (full)
```sh
   1  #!/bin/zsh
   2  set -euo pipefail
   3  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
   4  OUT="${1:-$ROOT_DIR/site/images}"
   5  cd "$ROOT_DIR"
   6  SKIP_TESTS="${SKIP_TESTS:-1}" SKIP_LAUNCH=1 SKIP_INSTALL=1 SKIP_VERIFY=1 "$ROOT_DIR/scripts/build-and-run.sh"
   7  "$ROOT_DIR/build/ezkey.app/Contents/MacOS/ezkey" --render-marketing "$OUT"
```

### .github/workflows/ci.yml (full)
```yaml
   1  name: ci
   2  
   3  on:
   4    push:
   5      branches: [master]
   6    pull_request:
   7  
   8  permissions:
   9    contents: read
  10  
  11  jobs:
  12    test:
  13      runs-on: macos-15
  14      steps:
  15        - name: Checkout
  16          uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  17          with:
  18            persist-credentials: false
  19        - name: Show Swift
  20          run: swift --version
  21        - name: Test
  22          run: swift test --package-path .
  23        - name: Build the app the way install.sh does (not uploaded)
  24          env:
  25            SKIP_TESTS: "1"
  26            SKIP_VERIFY: "1"
  27            SKIP_INSTALL: "1"
  28          run: |
  29            ./scripts/build-and-run.sh
  30            codesign --verify --deep --strict build/ezkey.app
  31  
  32    site-test:
  33      runs-on: ubuntu-24.04
  34      steps:
  35        - name: Checkout
  36          uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  37          with:
  38            persist-credentials: false
  39        - name: Site worker tests
  40          run: node --experimental-strip-types --test tests/site/worker.test.ts tests/site/public-repo.test.ts tests/site/review-checklist.test.ts
  41  
  42    ci-gate:
  43      if: always()
  44      needs: [test, site-test]
  45      runs-on: ubuntu-24.04
  46      permissions:
  47        contents: read
  48      steps:
  49        - name: Require test success
  50          run: test "${{ needs.test.result }}" = "success" && test "${{ needs.site-test.result }}" = "success"
```

### RELEASING.md (full). Releases are source-only `v*` tags, and no binaries are built or uploaded.
```md
   1  # Releasing
   2  
   3  A release is a `v*` tag on `master`. Installs clone the newest one (see `site/.well-known/agent-skills/build-ezkey/SKILL.md`). Nothing is built or uploaded: there are no binaries.
   4  
   5  1. Bump `CFBundleShortVersionString` in `Resources/Info.plist` through a PR. `ci-gate` must pass. It includes `tests/site/review-checklist.test.ts`, which fails if the code no longer matches what the install skill tells agents to expect.
   6  2. Tag the merge commit and push the tag:
   7  
   8     ```sh
   9     git switch master && git pull
  10     git tag v1.0.1 && git push origin v1.0.1
  11     ```
  12  
  13  Only admins can create, move, or delete `v*` tags (`release-tags` ruleset). Never move a published tag: agents and users pin to it.
  14  
  15  Use a plain tag (`git tag`, not `git tag -a`). With an annotated tag, `git clone --depth 1 --branch <tag>` prints "is not a commit!", which a reviewing agent may flag. GitHub prints "Cannot create ref due to creations being restricted" when an admin bypasses the ruleset; the tag is still created.
```

Other scripts (not pasted because they don't build or sign): `scripts/probe-keychain.swift` and `scripts/verify-roundtrip.swift` are standalone keychain interop probes that shell out to `/usr/bin/security` (see §5). `scan-public.sh` is a secret/PII scanner. `render_guides.py` generates the site.

## 2. Sources/EZKeyCore/LoginKeychainStore.swift (full, 302 lines)
```swift
   1  import Foundation
   2  import Security
   3  
   4  public protocol SecretStore: Sendable {
   5      func contains(_ identity: SecretIdentity) async throws -> Bool
   6      func add(_ identity: SecretIdentity, secret: String, note: String) async throws
   7      func update(_ identity: SecretIdentity, secret: String, note: String) async throws
   8      func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret
   9      func comment(for identity: SecretIdentity) async throws -> String
  10      func list(matching query: String) async throws -> [SecretIdentity]
  11      func delete(_ identity: SecretIdentity) async throws
  12  }
  13  
  14  /// Generic-password access to the user's file-based login Keychain.
  15  ///
  16  /// SecItem's default data-protection store is a different database than
  17  /// `~/Library/Keychains/login.keychain-db`. This type opens that file
  18  /// explicitly so items round-trip with `/usr/bin/security`.
  19  ///
  20  /// File-based Keychain APIs are deprecated by Apple in favor of the data-
  21  /// protection keychain. They remain the correct API for this compatibility
  22  /// requirement.
  23  public actor LoginKeychainStore: SecretStore {
  24      /// Who may read a secret ezkey saves without the macOS password prompt.
  25      public enum ReadPolicy: Sendable {
  26          /// Every read asks for the login password, including reads by ezkey.
  27          /// macOS would otherwise let the saving app read silently.
  28          case askEveryTime
  29          /// macOS default: the saving app reads without a prompt.
  30          case trustEzkey
  31      }
  32  
  33      public let keychainPath: String
  34      public let readPolicy: ReadPolicy
  35      /// When false, Keychain calls fail instead of showing a password dialog.
  36      /// Tests use this so an unexpected ACL prompt cannot hang the suite.
  37      public let allowsPrompt: Bool
  38  
  39      public init(
  40          keychainPath: String = LoginKeychainStore.defaultLoginPath,
  41          allowsPrompt: Bool = true,
  42          readPolicy: ReadPolicy = .askEveryTime
  43      ) {
  44          self.keychainPath = keychainPath
  45          self.allowsPrompt = allowsPrompt
  46          self.readPolicy = readPolicy
  47      }
  48  
  49      public static var defaultLoginPath: String {
  50          FileManager.default.homeDirectoryForCurrentUser
  51              .appendingPathComponent("Library/Keychains/login.keychain-db")
  52              .path
  53      }
  54  
  55      public func contains(_ identity: SecretIdentity) async throws -> Bool {
  56          try requireValid(identity)
  57          var result: CFTypeRef?
  58          let status = SecItemCopyMatching(try searchQuery(identity, returnData: false) as CFDictionary, &result)
  59          switch status {
  60          case errSecSuccess:
  61              return true
  62          case errSecItemNotFound:
  63              return false
  64          case errSecInteractionNotAllowed, errSecAuthFailed:
  65              // Attributes were gated; the item exists.
  66              return true
  67          default:
  68              throw KeychainError.from(status: status)
  69          }
  70      }
  71  
  72      public func add(_ identity: SecretIdentity, secret: String, note: String = "") async throws {
  73          try requireValid(identity)
  74          try requireSecret(secret)
  75          let keychain = try openLoginKeychain()
  76          var query: [CFString: Any] = [
  77              kSecClass: kSecClassGenericPassword,
  78              kSecAttrService: identity.service,
  79              kSecAttrLabel: identity.service,
  80              kSecAttrAccount: identity.account,
  81              kSecValueData: Data(secret.utf8),
  82              kSecUseKeychain: keychain,
  83              kSecUseDataProtectionKeychain: false
  84          ]
  85          let trimmedNote = StoredSecret.normalizedNote(note)
  86          if !trimmedNote.isEmpty {
  87              query[kSecAttrComment] = trimmedNote
  88          }
  89          if readPolicy == .askEveryTime {
  90              query[kSecAttrAccess] = try askEveryTimeAccess()
  91          }
  92          let status = SecItemAdd(query as CFDictionary, nil)
  93          try check(status)
  94      }
  95  
  96      public func update(_ identity: SecretIdentity, secret: String, note: String = "") async throws {
  97          try requireValid(identity)
  98          try requireSecret(secret)
  99          // Replacing a secret destroys the old one, so it needs the same
 100          // password prompt as reading it. SecItemUpdate alone is silent.
 101          let readQuery = try searchQuery(identity, returnData: true)
 102          var current: CFTypeRef?
 103          try check(withPromptPolicy { SecItemCopyMatching(readQuery as CFDictionary, &current) })
 104          var query = try searchQuery(identity, returnData: false)
 105          query[kSecUseAuthenticationUI] = allowsPrompt
 106              ? kSecUseAuthenticationUIAllow
 107              : kSecUseAuthenticationUIFail
 108          let attributes: [CFString: Any] = [
 109              kSecValueData: Data(secret.utf8),
 110              kSecAttrComment: StoredSecret.normalizedNote(note)
 111          ]
 112          let status = withPromptPolicy { SecItemUpdate(query as CFDictionary, attributes as CFDictionary) }
 113          try check(status)
 114      }
 115  
 116      public func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret {
 117          try requireValid(identity)
 118          var query = try searchQuery(identity, returnData: true)
 119          query[kSecReturnAttributes] = true
 120          var result: CFTypeRef?
 121          let status = withPromptPolicy { SecItemCopyMatching(query as CFDictionary, &result) }
 122          try check(status)
 123          return try storedSecret(from: result)
 124      }
 125  
 126      public func comment(for identity: SecretIdentity) async throws -> String {
 127          try requireValid(identity)
 128          var result: CFTypeRef?
 129          let status = SecItemCopyMatching(try searchQuery(identity, returnData: false) as CFDictionary, &result)
 130          try check(status)
 131          return Self.commentString(from: result)
 132      }
 133  
 134      public static let matchLimit = 50
 135  
 136      public func list(matching query: String) async throws -> [SecretIdentity] {
 137          let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
 138          guard !needle.isEmpty else { return [] }
 139          let keychain = try openLoginKeychain()
 140          let search: [CFString: Any] = [
 141              kSecClass: kSecClassGenericPassword,
 142              kSecMatchSearchList: [keychain],
 143              kSecUseDataProtectionKeychain: false,
 144              kSecReturnAttributes: true,
 145              kSecReturnData: false,
 146              kSecMatchLimit: kSecMatchLimitAll,
 147              kSecUseAuthenticationUI: kSecUseAuthenticationUISkip
 148          ]
 149          var result: CFTypeRef?
 150          let status = SecItemCopyMatching(search as CFDictionary, &result)
 151          if status == errSecItemNotFound {
 152              return []
 153          }
 154          try check(status)
 155          let records: [NSDictionary]
 156          if let dicts = result as? [NSDictionary] {
 157              records = dicts
 158          } else if let array = result as? NSArray {
 159              records = array.compactMap { $0 as? NSDictionary }
 160          } else {
 161              return []
 162          }
 163          var seen = Set<SecretIdentity>()
 164          var matches: [SecretIdentity] = []
 165          for record in records {
 166              let service = record[kSecAttrService] as? String ?? ""
 167              let account = record[kSecAttrAccount] as? String ?? ""
 168              let label = record[kSecAttrLabel] as? String ?? ""
 169              let identity = SecretIdentity(service: service, account: account)
 170              guard identity.isValid else { continue }
 171              let comment = Self.commentString(from: record)
 172              let haystack = [identity.service, identity.account, label, comment]
 173              guard haystack.contains(where: { $0.localizedCaseInsensitiveContains(needle) }) else { continue }
 174              guard seen.insert(identity).inserted else { continue }
 175              matches.append(identity)
 176          }
 177          matches.sort {
 178              ($0.service.localizedLowercase, $0.account.localizedLowercase)
 179                  < ($1.service.localizedLowercase, $1.account.localizedLowercase)
 180          }
 181          if matches.count > Self.matchLimit {
 182              return Array(matches.prefix(Self.matchLimit))
 183          }
 184          return matches
 185      }
 186  
 187      public func delete(_ identity: SecretIdentity) async throws {
 188          try requireValid(identity)
 189          let status = SecItemDelete(try searchQuery(identity, returnData: false) as CFDictionary)
 190          if status == errSecItemNotFound {
 191              return
 192          }
 193          try check(status)
 194      }
 195  
 196      private func storedSecret(from result: CFTypeRef?) throws -> StoredSecret {
 197          let note = Self.commentString(from: result)
 198          if let data = result as? Data {
 199              guard let secret = String(data: data, encoding: .utf8) else {
 200                  throw KeychainError.failure(errSecDecode)
 201              }
 202              return StoredSecret(secret: secret, note: note)
 203          }
 204          guard let dict = result as? NSDictionary else {
 205              throw KeychainError.failure(errSecDecode)
 206          }
 207          guard let data = dict[kSecValueData] as? Data,
 208                let secret = String(data: data, encoding: .utf8)
 209          else {
 210              throw KeychainError.failure(errSecDecode)
 211          }
 212          return StoredSecret(secret: secret, note: note)
 213      }
 214  
 215      static func commentString(from result: Any?) -> String {
 216          guard let dict = result as? NSDictionary else { return "" }
 217          if let text = dict[kSecAttrComment] as? String {
 218              return text
 219          }
 220          if let data = dict[kSecAttrComment] as? Data,
 221             let text = String(data: data, encoding: .utf8) {
 222              return text
 223          }
 224          return ""
 225      }
 226  
 227      private func requireValid(_ identity: SecretIdentity) throws {
 228          guard identity.isValid else { throw KeychainError.invalidIdentity }
 229      }
 230  
 231      private func requireSecret(_ secret: String) throws {
 232          guard !secret.isEmpty else { throw KeychainError.emptySecret }
 233      }
 234  
 235      private func check(_ status: OSStatus) throws {
 236          guard status == errSecSuccess else {
 237              throw KeychainError.from(status: status)
 238          }
 239      }
 240  
 241      private func searchQuery(_ identity: SecretIdentity, returnData: Bool) throws -> [CFString: Any] {
 242          let keychain = try openLoginKeychain()
 243          var query: [CFString: Any] = [
 244              kSecClass: kSecClassGenericPassword,
 245              kSecAttrService: identity.service,
 246              kSecAttrAccount: identity.account,
 247              kSecMatchLimit: kSecMatchLimitOne,
 248              kSecMatchSearchList: [keychain],
 249              kSecUseDataProtectionKeychain: false
 250          ]
 251          if returnData {
 252              query[kSecReturnData] = true
 253              query[kSecUseAuthenticationUI] = allowsPrompt
 254                  ? kSecUseAuthenticationUIAllow
 255                  : kSecUseAuthenticationUIFail
 256          } else {
 257              query[kSecReturnData] = false
 258              query[kSecReturnAttributes] = true
 259              query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
 260          }
 261          return query
 262      }
 263  
 264      /// kSecUseAuthenticationUI does not stop the file-based Keychain's password
 265      /// dialog, so with prompts off this also turns off Keychain UI for the call.
 266      private func withPromptPolicy(_ call: () -> OSStatus) -> OSStatus {
 267          guard !allowsPrompt else { return call() }
 268          SecKeychainSetUserInteractionAllowed(false)
 269          defer { SecKeychainSetUserInteractionAllowed(true) }
 270          return call()
 271      }
 272  
 273      /// Starts from the default access (this app trusted for everything), then
 274      /// empties the trusted-app list on the decrypt rule. Reading the secret
 275      /// prompts for every app, ezkey included; names, notes, update and delete
 276      /// stay silent. The prompt-selector passphrase flag is not set: macOS
 277      /// keeps 0x100 whatever is written (measured), and the login-Keychain
 278      /// dialog asks for the password anyway.
 279      private func askEveryTimeAccess() throws -> SecAccess {
 280          var created: SecAccess?
 281          try check(SecAccessCreate("ezkey" as CFString, nil, &created))
 282          guard let access = created,
 283                let acls = SecAccessCopyMatchingACLList(access, kSecACLAuthorizationDecrypt) as? [SecACL],
 284                !acls.isEmpty
 285          else {
 286              throw KeychainError.failure(errSecACLNotSimple)
 287          }
 288          for acl in acls {
 289              try check(SecACLSetContents(acl, [] as CFArray, "ezkey" as CFString, []))
 290          }
 291          return access
 292      }
 293  
 294      private func openLoginKeychain() throws -> SecKeychain {
 295          var keychain: SecKeychain?
 296          let status = SecKeychainOpen(keychainPath, &keychain)
 297          guard status == errSecSuccess, let keychain else {
 298              throw KeychainError.from(status: status)
 299          }
 300          return keychain
 301      }
 302  }
```

## 3. Tagging on add (LoginKeychainStore.swift:72-94)
| Attribute | Value | Cite |
|---|---|---|
| kSecClass | `kSecClassGenericPassword` (generic, not internet) | :77 |
| kSecAttrService | `identity.service`, the **literal** user-typed name (whitespace-trimmed, Models.swift:11-14). No prefix in the app. | :78 |
| kSecAttrLabel | same as service | :79 |
| kSecAttrAccount | `identity.account`, which is always `NSUserName()` in the app (PanelModel.swift:68,75,81) | :80 |
| kSecValueData | `Data(secret.utf8)` | :81 |
| kSecUseKeychain | the `SecKeychain` opened from `~/Library/Keychains/login.keychain-db` | :82, :294-301, :49-53 |
| kSecUseDataProtectionKeychain | `false` | :83 |
| kSecAttrComment | the trimmed note, set only when it is non-empty | :85-88 |
| kSecAttrAccess | `askEveryTimeAccess()` when readPolicy == .askEveryTime (the default) | :89-91 |
| Description / Generic / Creator / Type / Accessible / Synchronizable / AccessGroup | **not set** anywhere (git grep finds no hits) | none |

SecAccess/ACL: `SecAccessCreate("ezkey", nil, …)` creates the default access with the creating app trusted. The code then takes every ACL that covers `kSecACLAuthorizationDecrypt` and calls `SecACLSetContents(acl, [], "ezkey", [])`, which leaves an empty trusted-app list (:279-292). `"ezkey"` is the access/ACL **description string** shown in Keychain Access. It is the only place ezkey's name is written into an item, and it appears only on askEveryTime items. It is not a queryable attribute. Under `.trustEzkey` (used only by the self-test and unit tests) no kSecAttrAccess is set, so macOS applies its default ACL, which trusts the creating app.

**Is anything marking an item as ezkey-made?** No, ezkey writes no queryable marker. Its items look the same as `security add-generic-password -a $USER -s <name> -j <note>` items, and this is deliberate (see the doc comment at :14-22 and the self-test interop at EZKeyMain.swift:51-95). The only prefix is `DisposableEntry.servicePrefix = "ezkey.test."` (Models.swift:214-220), which is used for test and self-test items.

Update (:96-114): the code first reads the item with returnData under the prompt policy (:101-103), which forces the password prompt. It then runs `SecItemUpdate(searchQuery(returnData:false) + kSecUseAuthenticationUI, [kSecValueData, kSecAttrComment])`. ACL and attributes other than the comment are untouched.

Search query used by contains/comment/update/retrieve/delete (:241-262):
```
kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account,
kSecMatchLimit: kSecMatchLimitOne, kSecMatchSearchList: [loginKeychain], kSecUseDataProtectionKeychain: false
+ returnData: kSecReturnData true, kSecUseAuthenticationUI Allow|Fail (per allowsPrompt)
+ !returnData: kSecReturnData false, kSecReturnAttributes true, kSecUseAuthenticationUI Skip
```
retrieve adds `kSecReturnAttributes: true` (:118-119). delete passes the returnData:false query to `SecItemDelete` and treats errSecItemNotFound as success (:187-194).

## 4. Listing (LoginKeychainStore.swift:134-185)
- Query (:140-148): `kSecClassGenericPassword`, `kSecMatchSearchList: [login keychain]`, `kSecUseDataProtectionKeychain: false`, `kSecReturnAttributes: true`, `kSecReturnData: false`, `kSecMatchLimit: kSecMatchLimitAll`, `kSecUseAuthenticationUI: Skip`. There is **no service or account filter**, so it reads every generic password in login.keychain-db, including items from other apps.
- Client-side filter (:163-176): the code skips records missing service or account, then case-insensitively matches the substring needle against service, account, label, and comment. It dedupes by (service, account), sorts by lowercased (service, account) (:177-180), and caps at `matchLimit = 50` (:134, :181-183). An empty needle returns [] (:137-138).
- The app calls `list` only after an exact `contains(service, NSUserName())` misses (PanelModel.swift:216-221).
- **No index file.** UserDefaults stores only `ezkey.service` (the last typed name) and `ezkey.account` (PanelModel.swift:61-62, 74, 301-304), plus a login-item flag in LoginItem.swift:19,30. MarketingRender uses a separate `UserDefaults(suiteName: "ezkey.marketing")` (MarketingRender.swift:76).

## 5. Callers of the store, and /usr/bin/security shell-outs
Callers of `LoginKeychainStore` / `SecretStore`:
- `PanelModel.init(store: any SecretStore = LoginKeychainStore(), …)` at PanelModel.swift:48,64-65 uses the default `.askEveryTime` with prompts allowed. Its calls are: `contains` :132, `add` :137 (save), `update` :189 (replaceRetrieved), `contains` :217 and `list` :221 (retrieve), and `retrieve` :254 (fetchSecret). The UI never calls `delete`.
- The app UI is `AppDelegate.applicationDidFinishLaunching` → `MenuBarController(model: PanelModel())` (EZKeyApp.swift:104-105). `PanelView` (Sources/ezkey/PanelView.swift) talks only to the PanelModel and makes no direct store or SecItem calls.
- The `--self-test` mode (EZKeyApp.swift:90-95) runs `SelfTest.run()` with `LoginKeychainStore(allowsPrompt:false, readPolicy:.trustEzkey)` and `LoginKeychainStore(allowsPrompt:false)` (EZKeyMain.swift:10-12). It touches only `ezkey.test.*` items.
- `--render-marketing` (EZKeyApp.swift:96-103) uses the in-memory `MemorySecretStore` (MarketingRender.swift:72, 184).
- Tests: LoginKeychainStoreTests.swift:11-12 (same two configs as the self-test) and `MockStore` in PanelModelTests.swift:4.
- **There is no separate CLI target.** The single executable `ezkey` is the menu-bar app (`LSUIElement` true), and its only CLI flags are `--self-test` and `--render-marketing`.

`/usr/bin/security` shell-outs (all via `Process`):
- Sources/ezkey/EZKeyMain.swift:201-218 (`runSecurityCapture`), called from :162-169 (`find-generic-password -a -s <keychain>`), :171-178 (same, capturing output), :180-195 (`add-generic-password -U -A -a -s -w [-j] <keychain>`, guarded to `ezkey.test.` items at :181), and :145-150 (`delete-generic-password`). These run only in the self-test.
- scripts/probe-keychain.swift:21-22, 46-47, 73-74, and scripts/verify-roundtrip.swift:25-26, 106-107. These are standalone scripts. verify-roundtrip also builds an ACL trusting itself plus `/usr/bin/security` via `SecTrustedApplicationCreateFromPath` (verify-roundtrip.swift:44-55).
- The production code paths (PanelModel → LoginKeychainStore) **never** shell out. They use only SecItem/SecKeychain/SecAccess.

## 6. How "ask every time" works (LoginKeychainStore.swift:24-31, 89-91, 264-292)
It is a **legacy file-keychain SecAccess/SecACL** setup. It does not use LAContext, SecAccessControl/userPresence, or a custom prompt.
1. On add with `.askEveryTime` (the default, :42), `kSecAttrAccess = askEveryTimeAccess()` (:89-91).
2. `askEveryTimeAccess` (:279-292) calls `SecAccessCreate("ezkey", nil, &access)` (default ACLs, creating app trusted). It then runs `SecAccessCopyMatchingACLList(access, kSecACLAuthorizationDecrypt)` and throws `errSecACLNotSimple` if that is empty. For each decrypt ACL it calls `SecACLSetContents(acl, [] as CFArray, "ezkey", [])`, which empties the trusted-application list. The prompt selector is left at `[]`. Per the comment at :276-278, macOS keeps 0x100 regardless, and the login-keychain dialog asks for the password anyway.
3. As a result, reading the secret (anything with kSecReturnData) makes macOS show its own **keychain password dialog** for every app, ezkey included. Attribute reads (names, notes), update's attribute write, and delete stay silent (:273-276). Update deliberately does a returnData read first so that replacing a secret also prompts (:99-103).
4. `allowsPrompt:false` (tests/self-test) sets `kSecUseAuthenticationUIFail` (:253-255) and wraps calls in `SecKeychainSetUserInteractionAllowed(false)` (:264-271), because kSecUseAuthenticationUI doesn't suppress the file-keychain dialog. A gated read then fails with errSecInteractionNotAllowed/errSecAuthFailed, which maps to `KeychainError.accessDenied` (Models.swift:75-76). The self-test checks this at EZKeyMain.swift:125-138.
5. `contains` treats errSecInteractionNotAllowed/errSecAuthFailed as "exists" (:64-66).

**Toggle implication:** SecAccess/SecACL works only with the file-based keychain. On the data-protection keychain (required for `kSecAttrSynchronizable`/iCloud), the equivalent would be `SecAccessControlCreateWithFlags(…, .userPresence)` + `LAContext`. Note that synchronizable items cannot use SecAccessControl with userPresence/biometry, so an iCloud-synced item would lose ask-every-time unless ezkey adds an app-level LAContext gate. This last point is general Apple keychain behavior, not something in this repo.

## 7. Platforms and targets
- `platforms: [.macOS(.v14)]` (Package.swift:6-8). `LSMinimumSystemVersion` is 14.0 (Info.plist:25-26). CI runs on `macos-15` (ci.yml:13). The tools version is Swift 6.1 (Package.swift:1).
- Targets: `EZKeyCore` library (links AppKit + Security, Package.swift:14-20), `ezkey` executable (links ServiceManagement, :21-27), and `EZKeyCoreTests` (:28-31).
- **No iOS target.** git grep finds no `iOS`, `UIKit`, `#if os`, or `canImport` in Sources/, Tests/, or Package.swift. The only "iOS" mention is a site comparison table row in scripts/render_guides.py:361. EZKeyCore links AppKit (Package.swift:17), and the store uses macOS-only file-keychain APIs (SecKeychainOpen, SecAccess, SecACL, SecKeychainSetUserInteractionAllowed), so as written it would not compile for iOS.
- Bundle ID is `app.ezkey` and the version is 1.0.2 (1) (Info.plist:13-14, 21-24). Signing is ad-hoc (`codesign --sign -`) unless `EZKEY_SIGN_IDENTITY` is set (build-and-run.sh:13, 39-45). There are no entitlements.
