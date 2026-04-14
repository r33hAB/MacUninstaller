import Foundation

final class SuggestionEngine {
    private let duplicateDetector = DuplicateDetector()

    func generateAll(
        files: [StorageCategory: [ScannedFile]],
        installedAppNames: Set<String>
    ) -> [CleanupSuggestion] {
        let allFiles = files.values.flatMap { $0 }
        let downloadFiles = files[.downloads] ?? []
        let desktopFiles = files[.other] ?? []
        let devFiles = files[.developer] ?? []
        let cacheFiles = files[.caches] ?? []

        var suggestions: [CleanupSuggestion] = []

        let oldInstallers = detectOldInstallers(files: downloadFiles, installedAppNames: installedAppNames)
        if !oldInstallers.isEmpty { suggestions.append(CleanupSuggestion(type: .oldInstallers, files: oldInstallers)) }

        let stale = detectStaleDownloads(files: downloadFiles)
        if !stale.isEmpty { suggestions.append(CleanupSuggestion(type: .staleDownloads, files: stale)) }

        let dupes = detectDuplicates(files: allFiles)
        if !dupes.isEmpty { suggestions.append(CleanupSuggestion(type: .duplicates, files: dupes)) }

        let nearDupes = detectNearDuplicates(files: allFiles)
        if !nearDupes.isEmpty { suggestions.append(CleanupSuggestion(type: .nearDuplicates, files: nearDupes)) }

        let extracted = detectExtractedArchives(files: downloadFiles)
        if !extracted.isEmpty { suggestions.append(CleanupSuggestion(type: .extractedArchives, files: extracted)) }

        let large = detectLargeFiles(files: allFiles)
        if !large.isEmpty { suggestions.append(CleanupSuggestion(type: .largeFiles, files: large)) }

        if !devFiles.isEmpty { suggestions.append(CleanupSuggestion(type: .devArtifacts, files: devFiles)) }

        let screenshots = detectOldScreenshots(files: desktopFiles)
        if !screenshots.isEmpty { suggestions.append(CleanupSuggestion(type: .oldScreenshots, files: screenshots)) }

        let bloatedCaches = detectCacheBloat(files: cacheFiles)
        if !bloatedCaches.isEmpty { suggestions.append(CleanupSuggestion(type: .cacheBloat, files: bloatedCaches)) }

        let strayApps = detectAppsInDownloads(files: downloadFiles + desktopFiles)
        if !strayApps.isEmpty { suggestions.append(CleanupSuggestion(type: .appsInDownloads, files: strayApps)) }

        return suggestions.sorted { $0.totalSize > $1.totalSize }
    }

    func detectOldInstallers(files: [ScannedFile], installedAppNames: Set<String>) -> [ScannedFile] {
        files.filter { file in
            let ext = file.path.pathExtension.lowercased()
            guard ext == "dmg" || ext == "pkg" else { return false }
            let baseName = file.path.deletingPathExtension().lastPathComponent
            return installedAppNames.contains { appName in
                baseName.localizedCaseInsensitiveContains(appName) ||
                appName.localizedCaseInsensitiveContains(baseName)
            }
        }
    }

    func detectStaleDownloads(files: [ScannedFile]) -> [ScannedFile] {
        files.filter { $0.category == .downloads && $0.isStale }
    }

    func detectLargeFiles(files: [ScannedFile]) -> [ScannedFile] {
        files.filter { $0.isLarge && $0.path.pathExtension.lowercased() != "app" }
    }

    func detectOldScreenshots(files: [ScannedFile]) -> [ScannedFile] {
        files.filter { file in
            let name = file.name.lowercased()
            let isScreenshot = name.hasPrefix("screenshot") || name.hasPrefix("screen shot")
                || name.hasPrefix("skjermbilde") || name.contains("screenshot")
            let isOld = Calendar.current.dateComponents(
                [.day], from: file.dateModified ?? .distantPast, to: Date()
            ).day ?? 0 > 30
            return isScreenshot && isOld
        }
    }

    func detectAppsInDownloads(files: [ScannedFile]) -> [ScannedFile] {
        files.filter { $0.path.pathExtension.lowercased() == "app" }
    }

    func detectCacheBloat(files: [ScannedFile]) -> [ScannedFile] {
        // Since we now scan top-level only, each file IS an app cache folder
        // Just filter for ones > 500MB
        return files.filter { $0.size > 500_000_000 }
    }

    private func detectDuplicates(files: [ScannedFile]) -> [ScannedFile] {
        // Only check files > 100KB to avoid noise and performance issues
        let candidates = files.filter { $0.size > 100_000 }
        let sizeGroups = duplicateDetector.groupBySize(candidates)

        var allDupes: [ScannedFile] = []
        // Cap at 200 groups to prevent hangs on huge file sets
        for group in sizeGroups.prefix(200) {
            let headMatches = duplicateDetector.findDuplicates(in: group)
            for headGroup in headMatches {
                // Skip full-hash confirmation for files > 100MB (too expensive)
                if headGroup.first?.size ?? 0 > 100_000_000 {
                    allDupes.append(contentsOf: headGroup.dropFirst())
                } else {
                    let confirmed = duplicateDetector.confirmDuplicates(in: headGroup)
                    for dupeGroup in confirmed {
                        allDupes.append(contentsOf: dupeGroup.dropFirst())
                    }
                }
            }
        }
        return allDupes
    }

    private func detectNearDuplicates(files: [ScannedFile]) -> [ScannedFile] {
        // Only check files > 10KB in Downloads and Desktop to limit scope
        let candidates = files.filter {
            $0.size > 10_000 && ($0.category == .downloads || $0.category == .other)
        }
        let groups = duplicateDetector.findNearDuplicates(in: candidates)
        return groups.flatMap { group in
            let sorted = group.sorted { $0.name.count < $1.name.count }
            return Array(sorted.dropFirst())
        }
    }

    private func detectExtractedArchives(files: [ScannedFile]) -> [ScannedFile] {
        let archiveExts: Set<String> = ["zip", "tar", "gz", "rar", "7z"]
        let archiveFiles = files.filter { archiveExts.contains($0.path.pathExtension.lowercased()) }
        return archiveFiles.filter { archive in
            let parentDir = archive.path.deletingLastPathComponent()
            let siblings = (try? FileManager.default.contentsOfDirectory(atPath: parentDir.path)) ?? []
            return duplicateDetector.checkExtractedArchive(archivePath: archive.path, siblingNames: siblings)
        }
    }
}
