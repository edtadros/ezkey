import AppKit
import EZKeyCore
import SwiftUI

/// Offscreen snapshots of the real `PanelView` for the marketing site.
/// Uses an in-memory store and generic example names. Never reads Keychain.
enum MarketingRender {
    @MainActor
    static func run(outputDirectory: String) async -> Int32 {
        let dir = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let user = "macuser"
            for scheme in [ColorScheme.light, .dark] {
                let suffix = scheme == .dark ? "-dark" : ""
                try snapshot(name: "panel-save\(suffix)", scheme: scheme, directory: dir) { model in
                    model.mode = .save
                    model.service = "my-app-api-token"
                    model.secretToSave = "example-secret"
                    model.noteToSave = "local staging token"
                    model.status = .idle
                }
                try snapshot(name: "panel-retrieve\(suffix)", scheme: scheme, directory: dir) { model in
                    model.mode = .retrieve
                    model.service = "my-app"
                    model.status = .idle
                }
                try snapshot(name: "panel-matches\(suffix)", scheme: scheme, directory: dir) { model in
                    model.mode = .retrieve
                    model.service = "api"
                    model.matches = [
                        SecretIdentity(service: "my-app-api-token", account: user),
                        SecretIdentity(service: "openai-api-key", account: user),
                        SecretIdentity(service: "stripe-test-key", account: user),
                    ]
                    model.status = .chooseMatch
                }
                try snapshot(name: "panel-retrieved\(suffix)", scheme: scheme, directory: dir) { model in
                    model.mode = .retrieve
                    model.service = "my-app-api-token"
                    model.retrievedSecret = "sk_test_example"
                    model.retrievedNote = "local staging token"
                    model.isRevealed = false
                    model.status = .retrieved
                }
            }
            print("wrote marketing panels to \(dir.path)")
            return 0
        } catch {
            fputs("render-marketing failed: \(error)\n", stderr)
            return 1
        }
    }

    @MainActor
    private static func snapshot(
        name: String,
        scheme: ColorScheme,
        directory: URL,
        configure: @MainActor (PanelModel) -> Void
    ) throws {
        let store = MemorySecretStore()
        let model = PanelModel(
            store: store,
            clipboard: ClipboardGuard(pasteboard: NullPasteboard()),
            defaults: UserDefaults(suiteName: "ezkey.marketing") ?? .standard,
            currentUser: "macuser"
        )
        configure(model)
        let view = PanelView(model: model)
            .environment(\.colorScheme, scheme)
        let image = try rasterize(view: view, width: 340, scheme: scheme) {
            configure(model)
        }
        let url = directory.appendingPathComponent("\(name).png")
        try writePNG(image, to: url)
        print("wrote \(url.lastPathComponent)")
    }

    @MainActor
    private static func rasterize(
        view: some View,
        width: CGFloat,
        scheme: ColorScheme,
        afterVisible: @MainActor () -> Void
    ) throws -> NSImage {
        let appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        let background = scheme == .dark
            ? NSColor(calibratedWhite: 0.12, alpha: 1)
            : NSColor.windowBackgroundColor

        let root = view
            .frame(width: width, alignment: .topLeading)
            .background(Color(nsColor: background))
        let hosting = NSHostingView(rootView: root)
        hosting.appearance = appearance
        hosting.wantsLayer = true

        var fitting = hosting.fittingSize
        if fitting.width < 1 { fitting.width = width }
        if fitting.height < 120 { fitting.height = 400 }
        let frame = NSRect(x: -8000, y: -8000, width: width, height: fitting.height)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.appearance = appearance
        window.backgroundColor = background
        window.contentView = hosting
        hosting.frame = NSRect(origin: .zero, size: NSSize(width: width, height: fitting.height))
        hosting.layoutSubtreeIfNeeded()
        window.orderFrontRegardless()
        for _ in 0..<4 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03))
            hosting.layoutSubtreeIfNeeded()
        }
        afterVisible()
        for _ in 0..<6 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03))
            hosting.layoutSubtreeIfNeeded()
        }
        let laidOutHeight = max(hosting.fittingSize.height, 200)
        window.setFrame(NSRect(x: -8000, y: -8000, width: width, height: laidOutHeight), display: true)
        hosting.frame = NSRect(origin: .zero, size: NSSize(width: width, height: laidOutHeight))
        hosting.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        let bounds = hosting.bounds
        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw RenderError.noBitmap
        }
        hosting.cacheDisplay(in: bounds, to: bitmap)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmap)
        window.orderOut(nil)
        window.contentView = nil
        return image
    }

    private static func writePNG(_ image: NSImage, to url: URL) throws {
        guard
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            throw RenderError.pngFailed
        }
        try png.write(to: url)
    }
}

private enum RenderError: Error {
    case noBitmap
    case pngFailed
}

private actor MemorySecretStore: SecretStore {
    func contains(_ identity: SecretIdentity) async throws -> Bool { false }
    func add(_ identity: SecretIdentity, secret: String, note: String) async throws {}
    func update(_ identity: SecretIdentity, secret: String, note: String) async throws {}
    func retrieve(_ identity: SecretIdentity) async throws -> StoredSecret {
        throw KeychainError.missingEntry
    }
    func comment(for identity: SecretIdentity) async throws -> String {
        throw KeychainError.missingEntry
    }
    func list(matching query: String) async throws -> [SecretIdentity] { [] }
    func delete(_ identity: SecretIdentity) async throws {}
}

@MainActor
private final class NullPasteboard: PasteboardWriting {
    func write(_ string: String) {}
    func read() -> String? { nil }
    func clear() {}
}
