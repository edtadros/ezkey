import AppKit
import EZKeyCore
import SwiftUI

@MainActor
@Observable
final class EZKeySession {
    let model = PanelModel()

    init() {
        model.onOperationFinishedWhileClosed = {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                MenuBarReopener.reopen()
            }
        }
    }
}

@MainActor
enum MenuBarReopener {
    /// MenuBarExtra has no public present API. Click this process's status item
    /// so the panel comes back after a Keychain password dialog dismisses it.
    static func reopen() {
        NSApp.activate()
        guard let pointerArray = NSStatusBar.system.value(forKey: "items") as? NSPointerArray else {
            return
        }
        for index in 0..<pointerArray.count {
            guard let pointer = pointerArray.pointer(at: index) else { continue }
            let item = Unmanaged<NSStatusItem>.fromOpaque(pointer).takeUnretainedValue()
            if let button = item.button {
                button.performClick(nil)
                return
            }
        }
    }
}

@main
struct EZKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = EZKeySession()

    var body: some Scene {
        MenuBarExtra {
            PanelView(model: session.model)
        } label: {
            Image(systemName: "key.fill")
                .accessibilityLabel("ezkey")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Do not call setActivationPolicy(.accessory) here. LSUIElement in
        // Info.plist already hides the Dock icon; switching policy after
        // SwiftUI constructs MenuBarExtra removes the status item.
        if CommandLine.arguments.contains("--self-test") {
            Task { @MainActor in
                exit(await SelfTest.run())
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
