import XCTest
@testable import EZKeyCore

actor ManualSleeper: Sleeper {
    private var waiters: [CheckedContinuation<Void, Error>] = []

    func sleep(for duration: Duration) async throws {
        try await withCheckedThrowingContinuation { waiters.append($0) }
    }

    func releaseOne() async {
        for _ in 0..<200 {
            if !waiters.isEmpty {
                waiters.removeFirst().resume()
                return
            }
            await Task.yield()
        }
    }
}

@MainActor
final class ClipboardGuardTests: XCTestCase {
    func testClearsAfterDelayWhenUnchanged() async throws {
        let pasteboard = MockPasteboard()
        let sleeper = ManualSleeper()
        let clipboard = ClipboardGuard(pasteboard: pasteboard, sleeper: sleeper, clearAfter: .seconds(30))
        clipboard.copy("ezkey-secret")
        XCTAssertEqual(pasteboard.value, "ezkey-secret")
        await sleeper.releaseOne()
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertNil(pasteboard.value)
    }

    func testPreservesSubsequentUserCopy() async throws {
        let pasteboard = MockPasteboard()
        let sleeper = ManualSleeper()
        let clipboard = ClipboardGuard(pasteboard: pasteboard, sleeper: sleeper, clearAfter: .seconds(30))
        clipboard.copy("ezkey-secret")
        pasteboard.value = "user-copied-something-else"
        await sleeper.releaseOne()
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(pasteboard.value, "user-copied-something-else")
    }

    func testSecondCopyInvalidatesFirstClear() async throws {
        let pasteboard = MockPasteboard()
        let sleeper = ManualSleeper()
        let clipboard = ClipboardGuard(pasteboard: pasteboard, sleeper: sleeper, clearAfter: .seconds(30))
        clipboard.copy("first")
        clipboard.copy("second")
        await sleeper.releaseOne()
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(pasteboard.value, "second")
        await sleeper.releaseOne()
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertNil(pasteboard.value)
    }
}
