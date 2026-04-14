import XCTest
@testable import MacUninstaller

final class ScannedFileTests: XCTestCase {

    func test_fileExtensionGroup_dmgIsInstaller() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/Downloads/App.dmg"), size: 100_000, dateModified: Date(), dateAccessed: nil, category: .downloads)
        XCTAssertEqual(file.typeGroup, .installers)
    }

    func test_fileExtensionGroup_mp4IsVideo() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/Downloads/movie.mp4"), size: 100_000, dateModified: Date(), dateAccessed: nil, category: .downloads)
        XCTAssertEqual(file.typeGroup, .videos)
    }

    func test_fileExtensionGroup_zipIsArchive() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/Downloads/project.zip"), size: 100_000, dateModified: Date(), dateAccessed: nil, category: .downloads)
        XCTAssertEqual(file.typeGroup, .archives)
    }

    func test_fileExtensionGroup_unknownIsOther() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/Downloads/data.xyz"), size: 100_000, dateModified: Date(), dateAccessed: nil, category: .downloads)
        XCTAssertEqual(file.typeGroup, .other)
    }

    func test_ageBracket_recentFile() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/file.txt"), size: 100, dateModified: Date(), dateAccessed: nil, category: .documents)
        XCTAssertEqual(file.ageBracket, .last7Days)
    }

    func test_ageBracket_staleFile() {
        let file = ScannedFile(path: URL(filePath: "/Users/test/old.txt"), size: 100, dateModified: Calendar.current.date(byAdding: .day, value: -200, to: Date()), dateAccessed: nil, category: .documents)
        XCTAssertEqual(file.ageBracket, .olderThan6Months)
    }

    func test_isLargeFile() {
        let large = ScannedFile(path: URL(filePath: "/Users/test/big.bin"), size: 600_000_000, dateModified: Date(), dateAccessed: nil, category: .documents)
        XCTAssertTrue(large.isLarge)
        let small = ScannedFile(path: URL(filePath: "/Users/test/tiny.txt"), size: 1_000, dateModified: Date(), dateAccessed: nil, category: .documents)
        XCTAssertFalse(small.isLarge)
    }
}
