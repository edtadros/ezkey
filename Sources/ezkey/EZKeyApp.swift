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
            Image(nsImage: MenuBarIcon.image)
                .renderingMode(.template)
                .accessibilityLabel("ezkey")
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        let source = load() ?? NSImage(systemSymbolName: "key.fill", accessibilityDescription: "ezkey") ?? NSImage()
        let image = source.copy() as? NSImage ?? source
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 22)
        return image
    }()

    private static func load() -> NSImage? {
        if let named = NSImage(named: "MenuBarIcon") {
            return named
        }
        let urls = [
            Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("MenuBarIcon.png"),
        ]
        for url in urls.compactMap({ $0 }) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
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
            return
        }
        if let index = CommandLine.arguments.firstIndex(of: "--render-marketing") {
            let next = CommandLine.arguments.index(after: index)
            let directory = next < CommandLine.arguments.endIndex
                ? CommandLine.arguments[next]
                : "site/images"
            Task { @MainActor in
                exit(await MarketingRender.run(outputDirectory: directory))
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
