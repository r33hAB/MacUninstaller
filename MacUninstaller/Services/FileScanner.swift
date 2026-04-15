import Foundation

final class FileScanner {
    private let fileManager = FileManager.default

    private let devArtifactNames: Set<String> = [
        "node_modules", "DerivedData", ".build", "Pods",
        "venv", ".venv", ".gradle", "__pycache__", ".next",
        "build", "dist", "target", ".dart_tool",
    ]

    private var projectRoots: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appending(path: "Documents"),
            home.appending(path: "Developer"),
            home.appending(path: "Projects"),
            home.appending(path: "Code"),
            home.appending(path: "git"),
            home.appending(path: "repos"),
            home.appending(path: "src"),
            home.appending(path: "workspace"),
        ].filter { fileManager.fileExists(atPath: $0.path) }
    }

    func scanAll(fullDisk: Bool) async -> [(StorageCategory, [ScannedFile])] {
        let categories: [StorageCategory] = fullDisk
            ? StorageCategory.allCases.filter { $0 != .applications }
            : StorageCategory.allCases.filter { $0 != .applications && $0 != .system }

        return await withTaskGroup(of: (StorageCategory, [ScannedFile]).self) { group in
            for category in categories {
                group.addTask {
                    if category == .developer {
                        return (category, await self.scanDevArtifacts())
                    } else {
                        return (category, await self.scanCategory(category))
                    }
                }
            }

            var results: [(StorageCategory, [ScannedFile])] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.1.reduce(0) { $0 + $1.size } > $1.1.reduce(0) { $0 + $1.size } }
        }
    }

    func scanCategory(_ category: StorageCategory) async -> [ScannedFile] {
        return scanTopLevelFolders(category: category)
    }

    /// Scan only top-level items in each directory — each subfolder becomes one item with total size
    private func scanTopLevelFolders(category: StorageCategory) -> [ScannedFile] {
        var files: [ScannedFile] = []

        for directory in category.directories {
            guard fileManager.fileExists(atPath: directory.path),
                  let contents = try? fileManager.contentsOfDirectory(
                      at: directory,
                      includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                      options: [.skipsHiddenFiles]
                  ) else { continue }

            for url in contents {
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                let isDir = values?.isDirectory ?? false
                let modified = values?.contentModificationDate

                let size = isDir ? directorySize(url) : Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)

                files.append(ScannedFile(
                    path: url, size: size, dateModified: modified, dateAccessed: nil, category: category
                ))
            }
        }
        return files
    }

    func scanDevArtifacts() async -> [ScannedFile] {
        var artifacts: [ScannedFile] = []
        for root in projectRoots {
            guard let enumerator = fileManager.enumerator(
                at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
            ) else { continue }

            for case let url as URL in enumerator {
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let name = url.lastPathComponent

                if isDir && devArtifactNames.contains(name) {
                    let size = directorySize(url)
                    artifacts.append(ScannedFile(
                        path: url, size: size, dateModified: modificationDate(url), dateAccessed: nil, category: .developer
                    ))
                    enumerator.skipDescendants()
                }
                if url.pathComponents.count - root.pathComponents.count > 5 {
                    enumerator.skipDescendants()
                }
            }
        }
        return artifacts
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: []
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if values?.isDirectory == false { total += Int64(values?.fileSize ?? 0) }
        }
        return total
    }

    private func modificationDate(_ url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
