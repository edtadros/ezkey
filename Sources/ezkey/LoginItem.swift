import Foundation
import ServiceManagement

/// Registers this app with System Settings → General → Login Items.
/// Same API Raycast, Stats, and Apple's SMAppService sample use (macOS 13+).
enum LoginItem {
    private static let enabledKey = "ezkey.openAtLogin"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Keeps the login item pointed at whichever copy is running. Default is on.
    static func sync() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: enabledKey) == nil {
            defaults.set(true, forKey: enabledKey)
        }
        if defaults.bool(forKey: enabledKey) {
            _ = setEnabled(true)
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> String {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            return error.localizedDescription
        }
        if SMAppService.mainApp.status == .requiresApproval {
            return "Allow ezkey in System Settings → General → Login Items."
        }
        return ""
    }
}
