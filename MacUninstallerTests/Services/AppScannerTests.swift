import XCTest
@testable import MacUninstaller

final class AppScannerTests: XCTestCase {

    func test_scanDirectoryFindsAppBundles() async throws {
        let scanner = AppScanner()
        let apps = await scanner.scanDirectory(URL(filePath: "/Applications"))
        XCTAssertFalse(apps.isEmpty, "Should find at least one app in /Applications")
    }

    func test_scannedAppHasBundleIdentifier() async throws {
        let scanner = AppScanner()
        let apps = await scanner.scanDirectory(URL(filePath: "/Applications"))
        let firstApp = try XCTUnwrap(apps.first)
        XCTAssertFalse(firstApp.bundleIdentifier.isEmpty)
    }

    func test_scannedAppHasName() async throws {
        let scanner = AppScanner()
        let apps = await scanner.scanDirectory(URL(filePath: "/Applications"))
        let firstApp = try XCTUnwrap(apps.first)
        XCTAssertFalse(firstApp.name.isEmpty)
    }

    func test_scannedAppHasPositiveSize() async throws {
        let scanner = AppScanner()
        let apps = await scanner.scanDirectory(URL(filePath: "/Applications"))
        let firstApp = try XCTUnwrap(apps.first)
        XCTAssertGreaterThan(firstApp.bundleSize, 0)
    }

    func test_scanAllSourcesIncludesApplications() async {
        let scanner = AppScanner()
        let apps = await scanner.scanAll(includeSystem: false)
        XCTAssertFalse(apps.isEmpty)
    }

    func test_detectsAdminOwnedApps() async throws {
        let scanner = AppScanner()
        let apps = await scanner.scanDirectory(URL(filePath: "/Applications"))
        _ = apps.filter { $0.isAdminOwned }
    }
}
