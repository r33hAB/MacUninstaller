import XCTest
@testable import MacUninstaller

final class SuggestionEngineTests: XCTestCase {

    func test_detectOldInstallers_findsDMGsWithInstalledApps() {
        let engine = SuggestionEngine()
        let files = [
            ScannedFile(path: URL(filePath: "/Users/test/Downloads/Discord.dmg"), size: 100_000_000, dateModified: nil, dateAccessed: nil, category: .downloads),
        ]
        let suggestions = engine.detectOldInstallers(files: files, installedAppNames: ["Discord"])
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.name, "Discord.dmg")
    }

    func test_detectStaleDownloads_findsOldFiles() {
        let engine = SuggestionEngine()
        let files = [
            ScannedFile(path: URL(filePath: "/Users/test/Downloads/old.pdf"), size: 1000, dateModified: Calendar.current.date(byAdding: .day, value: -200, to: Date()), dateAccessed: nil, category: .downloads),
            ScannedFile(path: URL(filePath: "/Users/test/Downloads/new.pdf"), size: 1000, dateModified: Date(), dateAccessed: nil, category: .downloads),
        ]
        let stale = engine.detectStaleDownloads(files: files)
        XCTAssertEqual(stale.count, 1)
        XCTAssertEqual(stale.first?.name, "old.pdf")
    }

    func test_detectLargeFiles_findsFilesOver500MB() {
        let engine = SuggestionEngine()
        let files = [
            ScannedFile(path: URL(filePath: "/tmp/big.bin"), size: 600_000_000, dateModified: nil, dateAccessed: nil, category: .documents),
            ScannedFile(path: URL(filePath: "/tmp/small.txt"), size: 1000, dateModified: nil, dateAccessed: nil, category: .documents),
        ]
        let large = engine.detectLargeFiles(files: files)
        XCTAssertEqual(large.count, 1)
    }

    func test_detectOldScreenshots_findsOldScreenshotsOnDesktop() {
        let engine = SuggestionEngine()
        let files = [
            ScannedFile(path: URL(filePath: "/Users/test/Desktop/Screenshot 2024-01-01.png"), size: 500_000, dateModified: Calendar.current.date(byAdding: .day, value: -60, to: Date()), dateAccessed: nil, category: .other),
            ScannedFile(path: URL(filePath: "/Users/test/Desktop/Screenshot 2026-04-14.png"), size: 500_000, dateModified: Date(), dateAccessed: nil, category: .other),
        ]
        let old = engine.detectOldScreenshots(files: files)
        XCTAssertEqual(old.count, 1)
    }

    func test_generateAll_returnsNonEmptySuggestions() {
        let engine = SuggestionEngine()
        let allFiles: [StorageCategory: [ScannedFile]] = [
            .downloads: [
                ScannedFile(path: URL(filePath: "/Users/test/Downloads/old.zip"), size: 100_000, dateModified: Calendar.current.date(byAdding: .day, value: -200, to: Date()), dateAccessed: nil, category: .downloads),
            ]
        ]
        let suggestions = engine.generateAll(files: allFiles, installedAppNames: [])
        let stale = suggestions.filter { $0.type == .staleDownloads }
        XCTAssertFalse(stale.isEmpty)
    }
}
