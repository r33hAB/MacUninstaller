import XCTest
@testable import MacUninstaller

final class SIPCheckerTests: XCTestCase {

    func test_sipStatusReturnsBoolean() {
        let checker = SIPChecker()
        let isEnabled = checker.isSIPEnabled()
        XCTAssertTrue(isEnabled, "SIP should be enabled on a standard dev machine")
    }
}
