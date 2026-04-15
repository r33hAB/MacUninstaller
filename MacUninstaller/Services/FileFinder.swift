import Foundation

final class FileFinder {
    private let fileManager = FileManager.default

    func findAssociatedFiles(
        bundleIdentifier: String,
        appPath: URL
    ) async -> [AssociatedFile] {
        var files: [AssociatedFile] = []
        let home = fileManager.homeDirectoryForCurrentUser

        // User Library paths
        let userLibrary = home.appendingPathComponent("Library")
        let userSearches: [(String, FileCategory)] = [
            ("Application Support/\(bundleIdentifier)", .applicationSupport),
            ("Preferences/\(bundleIdentifier).plist", .preferences),
            ("Caches/\(bundleIdentifier)", .caches),
            ("Saved Application State/\(bundleIdentifier).savedState", .savedState),
            ("Logs/\(bundleIdentifier)", .logs),
            ("HTTPStorages/\(bundleIdentifier)", .httpStorages),
            ("WebKit/\(bundleIdentifier)", .webKit),
        ]

        for (subpath, category) in userSearches {
            let fullPath = userLibrary.appendingPathComponent(subpath)
            if let file = checkPath(fullPath, category: category, requiresAdmin: false) {
                files.append(file)
            }
        }

        // Also search Application Support by app name (some apps use name, not bundle ID)
        let appName = appPath.deletingPathExtension().lastPathComponent
        let appSupportByName = userLibrary
            .appendingPathComponent("Application Support")
            .appendingPathComponent(appName)
        if let file = checkPath(appSupportByName, category: .applicationSupport, requiresAdmin: false) {
            let isDuplicate = files.contains { $0.path == file.path }
            if !isDuplicate {
                files.append(file)
            }
        }

        // System Library paths (require admin)
        let systemLibrary = URL(filePath: "/Library")
        let systemSearches: [(String, FileCategory)] = [
            ("Application Support/\(bundleIdentifier)", .applicationSupport),
            ("Preferences/\(bundleIdentifier).plist", .preferences),
        ]

        for (subpath, category) in systemSearches {
            let fullPath = systemLibrary.appendingPathComponent(subpath)
            if let file = checkPath(fullPath, category: category, requiresAdmin: true) {
                files.append(file)
            }
        }

        // LaunchAgents and LaunchDaemons — search by matching bundle ID in filename
        files.append(contentsOf: searchDirectory(
            systemLibrary.appendingPathComponent("LaunchAgents"),
            matching: bundleIdentifier,
            category: .launchAgents,
            requiresAdmin: true
        ))

        files.append(contentsOf: searchDirectory(
            systemLibrary.appendingPathComponent("LaunchDaemons"),
            matching: bundleIdentifier,
            category: .launchDaemons,
            requiresAdmin: true
        ))

        return files
    }

    private func checkPath(
        _ url: URL,
        category: FileCategory,
        requiresAdmin: Bool
    ) -> AssociatedFile? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        // Don't follow symlinks outside Library
        if let resolved = try? url.resolvingSymlinksInPath() {
            let resolvedPath = resolved.path
            let isValid = resolvedPath.contains("/Library/")
                || resolvedPath.hasPrefix("/Applications")
                || resolvedPath.hasPrefix("/System/Applications")
            if !isValid { return nil }
        }

        let size = itemSize(url)
        return AssociatedFile(
            path: url,
            size: size,
            category: category,
            requiresAdmin: requiresAdmin
        )
    }

    private func searchDirectory(
        _ directory: URL,
        matching bundleIdentifier: String,
        category: FileCategory,
        requiresAdmin: Bool
    ) -> [AssociatedFile] {
        guard fileManager.fileExists(atPath: directory.path),
              let contents = try? fileManager.contentsOfDirectory(
                  at: directory,
                  includingPropertiesForKeys: nil,
                  options: [.skipsHiddenFiles]
              ) else { return [] }

        return contents.compactMap { url in
            guard url.lastPathComponent.contains(bundleIdentifier) else { return nil }
            return checkPath(url, category: category, requiresAdmin: requiresAdmin)
        }
    }

    private func itemSize(_ url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return Int64(attrs?[.size] as? UInt64 ?? 0)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }
}
