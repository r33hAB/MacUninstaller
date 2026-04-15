import XCTest
@testable import MacUninstaller

final class DuplicateDetectorTests: XCTestCase {

    func test_groupBySize_groupsFilesWithSameSize() {
        let detector = DuplicateDetector()
        let files = [
            ScannedFile(path: URL(filePath: "/tmp/a.txt"), size: 100, dateModified: nil, dateAccessed: nil, category: .documents),
            ScannedFile(path: URL(filePath: "/tmp/b.txt"), size: 100, dateModified: nil, dateAccessed: nil, category: .documents),
            ScannedFile(path: URL(filePath: "/tmp/c.txt"), size: 200, dateModified: nil, dateAccessed: nil, category: .documents),
        ]
        let groups = detector.groupBySize(files)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.count, 2)
    }

    func test_isNearDuplicate_detectsCopySuffix() {
        let detector = DuplicateDetector()
        XCTAssertTrue(detector.isNearDuplicate("report.pdf", "report (1).pdf"))
        XCTAssertTrue(detector.isNearDuplicate("photo.jpg", "photo copy.jpg"))
        XCTAssertTrue(detector.isNearDuplicate("file.txt", "file-2.txt"))
        XCTAssertTrue(detector.isNearDuplicate("doc.pdf", "doc - Copy.pdf"))
        XCTAssertFalse(detector.isNearDuplicate("readme.md", "license.md"))
    }

    func test_detectExtractedArchives_findsZipNextToFolder() {
        let detector = DuplicateDetector()
        let result = detector.checkExtractedArchive(
            archivePath: URL(filePath: "/Users/test/Downloads/project.zip"),
            siblingNames: ["project", "other.txt"]
        )
        XCTAssertTrue(result)
    }

    func test_detectExtractedArchives_falseWhenNoMatchingFolder() {
        let detector = DuplicateDetector()
        let result = detector.checkExtractedArchive(
            archivePath: URL(filePath: "/Users/test/Downloads/project.zip"),
            siblingNames: ["other", "readme.txt"]
        )
        XCTAssertFalse(result)
    }
}
