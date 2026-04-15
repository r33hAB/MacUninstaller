import XCTest
@testable import MacUninstaller

@MainActor
final class UninstallSheetViewModelTests: XCTestCase {

    private func makeApp() -> AppInfo {
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
            AssociatedFile(path: URL(filePath: "/tmp/a"), size: 50_000_000, category: .caches, requiresAdmin: false),
            AssociatedFile(path: URL(filePath: "/tmp/b"), size: 1_000, category: .preferences, requiresAdmin: false),
            AssociatedFile(path: URL(filePath: "/tmp/c"), size: 20_000_000, category: .applicationSupport, requiresAdmin: true),
        ]
        return app
    }

    func test_allFilesSelectedByDefault() {
        let vm = UninstallSheetViewModel(app: makeApp())
        XCTAssertTrue(vm.files.allSatisfy { $0.isSelected })
    }

    func test_totalSelectedSize_includesAppBundle() {
        let vm = UninstallSheetViewModel(app: makeApp())
        XCTAssertEqual(vm.totalSelectedSize, 170_001_000)
    }

    func test_deselectFile_reducesTotalSize() {
        let vm = UninstallSheetViewModel(app: makeApp())
        vm.toggleFile(at: 0)
        XCTAssertEqual(vm.totalSelectedSize, 120_001_000)
    }

    func test_selectAll_selectsAllFiles() {
        let vm = UninstallSheetViewModel(app: makeApp())
        vm.toggleFile(at: 0)
        vm.toggleFile(at: 1)
        vm.selectAll()
        XCTAssertTrue(vm.files.allSatisfy { $0.isSelected })
    }

    func test_filesByCategory_groupsCorrectly() {
        let vm = UninstallSheetViewModel(app: makeApp())
        let grouped = vm.filesByCategory
        XCTAssertEqual(grouped.count, 3)
    }

    func test_hasAdminFiles() {
        let vm = UninstallSheetViewModel(app: makeApp())
        XCTAssertTrue(vm.hasAdminFiles)
    }
}
