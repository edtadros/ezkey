import AppKit
import Foundation

@MainActor
public protocol PasteboardWriting: AnyObject {
    func write(_ string: String)
    func read() -> String?
    func clear()
}

@MainActor
public final class SystemPasteboard: PasteboardWriting {
    private let pasteboard: NSPasteboard

    public init(_ pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func write(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    public func read() -> String? {
        pasteboard.string(forType: .string)
    }

    public func clear() {
        pasteboard.clearContents()
    }
}

public protocol Sleeper: Sendable {
    func sleep(for duration: Duration) async throws
}

public struct RealSleeper: Sleeper {
    public init() {}

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

@MainActor
public final class ClipboardGuard {
    public static let defaultClearDelay: Duration = .seconds(30)

    private let pasteboard: PasteboardWriting
    private let sleeper: any Sleeper
    private let clearAfter: Duration
    private var generation = 0

    public init(
        pasteboard: PasteboardWriting? = nil,
        sleeper: any Sleeper = RealSleeper(),
        clearAfter: Duration = ClipboardGuard.defaultClearDelay
    ) {
        self.pasteboard = pasteboard ?? SystemPasteboard()
        self.sleeper = sleeper
        self.clearAfter = clearAfter
    }

    public func copy(_ value: String) {
        generation += 1
        let token = generation
        pasteboard.write(value)
        Task {
            try? await sleeper.sleep(for: clearAfter)
            clearIfUnchanged(value, token: token)
        }
    }

    private func clearIfUnchanged(_ value: String, token: Int) {
        guard token == generation else { return }
        if pasteboard.read() == value {
            pasteboard.clear()
        }
    }
}
