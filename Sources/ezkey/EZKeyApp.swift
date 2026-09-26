import AppKit
import EZKeyCore
import SwiftUI

@main
struct EZKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

/// The menu bar icon and its popover. ezkey owns both, so reopening the panel
/// after a Keychain password dialog is a public `NSPopover.show` call.
@MainActor
final class MenuBarController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    init(model: PanelModel) {
        super.init()
        item.button?.image = MenuBarIcon.image
        item.button?.setAccessibilityLabel("ezkey")
        item.button?.target = self
        item.button?.action = #selector(toggle)
        let host = NSHostingController(rootView: PanelView(model: model))
        // Without this the popover is placed for SwiftUI's first size guess
        // and floats about 180 pt below the menu bar.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient
        model.onOperationFinishedWhileClosed = { [weak self] in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                self?.show()
            }
        }
    }

    @objc private func toggle() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show()
        }
    }

    private func show() {
        guard let button = item.button, !popover.isShown else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let arguments = CommandLine.arguments
        if arguments.contains("--self-test") {
            Task { @MainActor in
                exit(await SelfTest.run())
            }
            return
        }
        if let index = arguments.firstIndex(of: "--render-marketing") {
            let next = arguments.index(after: index)
            let directory = next < arguments.endIndex ? arguments[next] : "site/images"
            Task { @MainActor in
                exit(await MarketingRender.run(outputDirectory: directory))
            }
            return
        }
        LoginItem.sync()
        menuBar = MenuBarController(model: PanelModel())
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
