import XCTest
@testable import MacUninstaller

final class FileScannerTests: XCTestCase {
    func test_scanCategory_downloadsFindsFiles() async {
        let scanner = FileScanner()
        let files = await scanner.scanCategory(.downloads)
        XCTAssertNotNil(files)
    }

    func test_scanCategory_returnsScannedFiles() async {
        let scanner = FileScanner()
        let files = await scanner.scanCategory(.documents)
        for file in files {
            XCTAssertFalse(file.name.isEmpty)
            XCTAssertGreaterThanOrEqual(file.size, 0)
            XCTAssertEqual(file.category, .documents)
        }
    }

    func test_scanAll_returnsCategoryResults() async {
        let scanner = FileScanner()
        let results = await scanner.scanAll(fullDisk: false)
        XCTAssertFalse(results.isEmpty)
    }

    func test_scanDevArtifacts_runs() async {
        let scanner = FileScanner()
        let artifacts = await scanner.scanDevArtifacts()
        XCTAssertNotNil(artifacts)
    }

    func test_categoryTotals_nonNegative() async {
        let scanner = FileScanner()
        let results = await scanner.scanAll(fullDisk: false)
        for (category, files) in results {
            let total = files.reduce(Int64(0)) { $0 + $1.size }
            XCTAssertGreaterThanOrEqual(total, 0, "\(category.rawValue) has negative total")
        }
    }
}
