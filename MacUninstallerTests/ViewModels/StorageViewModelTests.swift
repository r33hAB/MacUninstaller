import XCTest
@testable import MacUninstaller

@MainActor
final class StorageViewModelTests: XCTestCase {

    func test_initialState() {
        let vm = StorageViewModel()
        XCTAssertTrue(vm.categoryResults.isEmpty)
        XCTAssertTrue(vm.suggestions.isEmpty)
        XCTAssertFalse(vm.isScanning)
        XCTAssertNil(vm.selectedCategory)
    }

    func test_groupByType_groupsCorrectly() {
        let vm = StorageViewModel()
        let files = [
            ScannedFile(path: URL(filePath: "/tmp/a.dmg"), size: 100, dateModified: nil, dateAccessed: nil, category: .downloads),
            ScannedFile(path: URL(filePath: "/tmp/b.dmg"), size: 200, dateModified: nil, dateAccessed: nil, category: .downloads),
            ScannedFile(path: URL(filePath: "/tmp/c.pdf"), size: 50, dateModified: nil, dateAccessed: nil, category: .downloads),
        ]
        let groups = vm.groupFilesByType(files)
        let installerGroup = groups.first { $0.type == .installers }
        XCTAssertEqual(installerGroup?.files.count, 2)
        XCTAssertEqual(installerGroup?.totalSize, 300)
    }

    func test_groupByDate_groupsCorrectly() {
        let vm = StorageViewModel()
        let files = [
            ScannedFile(path: URL(filePath: "/tmp/new.txt"), size: 100, dateModified: Date(), dateAccessed: nil, category: .downloads),
            ScannedFile(path: URL(filePath: "/tmp/old.txt"), size: 100, dateModified: Calendar.current.date(byAdding: .day, value: -200, to: Date()), dateAccessed: nil, category: .downloads),
        ]
        let groups = vm.groupFilesByDate(files)
        let recentGroup = groups.first { $0.bracket == .last7Days }
        let staleGroup = groups.first { $0.bracket == .olderThan6Months }
        XCTAssertEqual(recentGroup?.files.count, 1)
        XCTAssertEqual(staleGroup?.files.count, 1)
    }

    func test_toggleFileSelection() {
        let vm = StorageViewModel()
        let file = ScannedFile(path: URL(filePath: "/tmp/test.txt"), size: 100, dateModified: nil, dateAccessed: nil, category: .downloads)
        vm.categoryResults = [.downloads: [file]]
        XCTAssertFalse(vm.categoryResults[.downloads]![0].isSelected)
        vm.toggleFileSelection(file.id, in: .downloads)
        XCTAssertTrue(vm.categoryResults[.downloads]![0].isSelected)
    }

    func test_selectedFiles_returnsOnlySelected() {
        let vm = StorageViewModel()
        var file1 = ScannedFile(path: URL(filePath: "/tmp/a.txt"), size: 100, dateModified: nil, dateAccessed: nil, category: .downloads)
        file1.isSelected = true
        let file2 = ScannedFile(path: URL(filePath: "/tmp/b.txt"), size: 200, dateModified: nil, dateAccessed: nil, category: .downloads)
        vm.categoryResults = [.downloads: [file1, file2]]
        XCTAssertEqual(vm.selectedFiles.count, 1)
        XCTAssertEqual(vm.selectedFilesTotalSize, 100)
    }
}
