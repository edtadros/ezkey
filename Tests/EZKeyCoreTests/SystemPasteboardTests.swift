import AppKit
import XCTest
@testable import EZKeyCore

@MainActor
final class SystemPasteboardTests: XCTestCase {
    func testWriteMarksSecretConcealedAndTransient() {
        let named = NSPasteboard(name: NSPasteboard.Name("ezkey.test.\(UUID().uuidString)"))
        defer { named.releaseGlobally() }
        SystemPasteboard(named).write("ezkey-secret")

        XCTAssertEqual(named.string(forType: .string), "ezkey-secret")
        let types = Set(named.types ?? [])
        XCTAssertTrue(types.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")))
        XCTAssertTrue(types.contains(NSPasteboard.PasteboardType("org.nspasteboard.TransientType")))
    }
}
