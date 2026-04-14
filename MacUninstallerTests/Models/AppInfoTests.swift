import XCTest
@testable import MacUninstaller

final class AppInfoTests: XCTestCase {

    func test_totalSize_sumsAppBundleAndAssociatedFiles() {
        var app = AppInfo(
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            bundlePath: URL(filePath: "/Applications/TestApp.app"),
            icon: nil,
            bundleSize: 100_000_000,
            source: .manual,
            installDate: nil,
            lastUsedDate: nil
        )
        app.associatedFiles = [
            AssociatedFile(path: URL(filePath: "/tmp/cache"), size: 50_000_000, category: .caches, requiresAdmin: false),
            AssociatedFile(path: URL(filePath: "/tmp/prefs"), size: 1_000, category: .preferences, requiresAdmin: false),
        ]
        XCTAssertEqual(app.totalSize, 150_001_000)
    }

    func test_associatedFilesSize_excludesAppBundle() {
        var app = AppInfo(
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            bundlePath: URL(filePath: "/Applications/TestApp.app"),
            icon: nil,
            bundleSize: 100_000_000,
            source: .manual,
            installDate: nil,
            lastUsedDate: nil
        )
        app.associatedFiles = [
            AssociatedFile(path: URL(filePath: "/tmp/cache"), size: 50_000_000, category: .caches, requiresAdmin: false),
        ]
        XCTAssertEqual(app.associatedFilesSize, 50_000_000)
    }

    func test_isUnused_trueWhenLastUsedOverThreshold() {
        let app = AppInfo(
            name: "OldApp",
            bundleIdentifier: "com.test.old",
            bundlePath: URL(filePath: "/Applications/OldApp.app"),
            icon: nil,
            bundleSize: 100,
            source: .manual,
            installDate: nil,
            lastUsedDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())
        )
        XCTAssertTrue(app.isUnused)
    }

    func test_isUnused_falseWhenRecentlyUsed() {
        let app = AppInfo(
            name: "NewApp",
            bundleIdentifier: "com.test.new",
            bundlePath: URL(filePath: "/Applications/NewApp.app"),
            icon: nil,
            bundleSize: 100,
            source: .manual,
            installDate: nil,
            lastUsedDate: Date()
        )
        XCTAssertFalse(app.isUnused)
    }

    func test_isUnused_trueWhenNeverUsed() {
        let app = AppInfo(
            name: "NeverApp",
            bundleIdentifier: "com.test.never",
            bundlePath: URL(filePath: "/Applications/NeverApp.app"),
            icon: nil,
            bundleSize: 100,
            source: .manual,
            installDate: nil,
            lastUsedDate: nil
        )
        XCTAssertTrue(app.isUnused)
    }

    func test_permissionTier_standardForUserOwnedApps() {
        let app = AppInfo(
            name: "MyApp",
            bundleIdentifier: "com.test.my",
            bundlePath: URL(filePath: "/Applications/MyApp.app"),
            icon: nil,
            bundleSize: 100,
            source: .manual,
            installDate: nil,
            lastUsedDate: nil,
            isAdminOwned: false
        )
        XCTAssertEqual(app.permissionTier, .standard)
    }

    func test_permissionTier_adminForRootOwnedApps() {
        let app = AppInfo(
            name: "AdminApp",
            bundleIdentifier: "com.test.admin",
            bundlePath: URL(filePath: "/Applications/AdminApp.app"),
            icon: nil,
            bundleSize: 100,
            source: .manual,
            installDate: nil,
            lastUsedDate: nil,
            isAdminOwned: true
        )
        XCTAssertEqual(app.permissionTier, .adminRequired)
    }

    func test_permissionTier_systemForSystemApps() {
        let app = AppInfo(
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            bundlePath: URL(filePath: "/System/Applications/Safari.app"),
            icon: nil,
            bundleSize: 100,
            source: .system,
            installDate: nil,
            lastUsedDate: nil
        )
        XCTAssertEqual(app.permissionTier, .system)
    }
}
