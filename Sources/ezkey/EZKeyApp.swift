import AppKit
import EZKeyCore
import SwiftUI

@main
struct EZKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = PanelModel()

    var body: some Scene {
        MenuBarExtra("ezkey", systemImage: "key.fill") {
            PanelView(model: model)
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
