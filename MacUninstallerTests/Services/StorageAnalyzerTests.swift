import XCTest
@testable import MacUninstaller

final class StorageAnalyzerTests: XCTestCase {

    private func makeSampleApps() -> [AppInfo] {
        [
            AppInfo(
                name: "BigApp",
                bundleIdentifier: "com.test.big",
                bundlePath: URL(filePath: "/Applications/BigApp.app"),
                icon: nil,
                bundleSize: 500_000_000,
                source: .manual,
                installDate: nil,
                lastUsedDate: Calendar.current.date(byAdding: .day, value: -200, to: Date())
            ),
            AppInfo(
                name: "SmallApp",
                bundleIdentifier: "com.test.small",
                bundlePath: URL(filePath: "/Applications/SmallApp.app"),
                icon: nil,
                bundleSize: 10_000_000,
                source: .appStore,
                installDate: nil,
                lastUsedDate: Date()
            ),
            AppInfo(
                name: "MediumApp",
                bundleIdentifier: "com.test.medium",
                bundlePath: URL(filePath: "/Applications/MediumApp.app"),
                icon: nil,
                bundleSize: 100_000_000,
                source: .manual,
                installDate: nil,
                lastUsedDate: Calendar.current.date(byAdding: .day, value: -50, to: Date())
            ),
        ]
    }

    func test_totalReclaimableSpace() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.totalReclaimableSpace, 610_000_000)
    }

    func test_totalAppCount() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.totalApps, 3)
    }

    func test_appStoreCount() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.appStoreApps, 1)
    }

    func test_unusedApps() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.unusedApps.count, 1)
        XCTAssertEqual(insights.unusedApps.first?.name, "BigApp")
    }

    func test_largestApp() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.largestApp?.name, "BigApp")
    }

    func test_unusedTotalSize() {
        let analyzer = StorageAnalyzer()
        let insights = analyzer.analyze(apps: makeSampleApps())
        XCTAssertEqual(insights.unusedTotalSize, 500_000_000)
    }
}
