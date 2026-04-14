import XCTest
@testable import MacUninstaller

final class FileFinderTests: XCTestCase {

    func test_findAssociatedFiles_returnsResultsForKnownApp() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        XCTAssertFalse(files.isEmpty, "Should find associated files for Finder")
    }

    func test_findAssociatedFiles_categoriesAreCorrect() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        for file in files {
            XCTAssertFalse(file.category.rawValue.isEmpty)
        }
    }

    func test_findAssociatedFiles_sizesAreNonNegative() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        for file in files {
            XCTAssertGreaterThanOrEqual(file.size, 0)
        }
    }

    func test_findAssociatedFiles_pathsExist() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        for file in files {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: file.path.path),
                "File should exist: \(file.path.path)"
            )
        }
    }

    func test_findAssociatedFiles_emptyForFakeBundleID() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.fake.nonexistent.app.xyz123",
            appPath: URL(filePath: "/Applications/FakeApp.app")
        )
        XCTAssertTrue(files.isEmpty)
    }

    func test_findAssociatedFiles_flagsAdminFiles() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        let adminFiles = files.filter { $0.requiresAdmin }
        for file in adminFiles {
            XCTAssertTrue(
                file.path.path.hasPrefix("/Library"),
                "Admin file should be in /Library: \(file.path.path)"
            )
        }
    }

    func test_doesNotFollowSymlinksOutsideLibrary() async {
        let finder = FileFinder()
        let files = await finder.findAssociatedFiles(
            bundleIdentifier: "com.apple.finder",
            appPath: URL(filePath: "/System/Applications/Finder.app")
        )
        for file in files {
            let path = file.path.path
            let isInLibrary = path.contains("/Library/") || path.hasPrefix("/Applications")
            XCTAssertTrue(isInLibrary, "File should be in Library or Applications: \(path)")
        }
    }
}
