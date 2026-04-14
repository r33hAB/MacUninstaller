import XCTest
@testable import MacUninstaller

final class MacUninstallerTests: XCTestCase {
    func testAppConstantsExist() {
        XCTAssertEqual(AppConstants.appBundleID, "io.darevader.MacUninstaller")
        XCTAssertEqual(AppConstants.unusedThresholdDays, 90)
        XCTAssertFalse(AppConstants.blockedPaths.isEmpty)
        XCTAssertFalse(AppConstants.librarySearchPaths.isEmpty)
    }
}
