import SwiftUI

struct TypeGroupResult: Identifiable {
    let type: FileTypeGroup
    let files: [ScannedFile]
    var id: String { type.rawValue }
    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }
    var fileCount: Int { files.count }
}

struct DateGroupResult: Identifiable {
    let bracket: AgeBracket
    let files: [ScannedFile]
    var id: String { bracket.rawValue }
    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }
    var fileCount: Int { files.count }
}

enum DetailViewMode: String, CaseIterable {
    case byFolder = "By Folder"
    case byType = "By Type"
    case byDate = "By Date"
}

struct FolderGroupResult: Identifiable {
    let name: String
    let path: URL
    let files: [ScannedFile]
    var id: String { path.path }
    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }
    var fileCount: Int { files.count }
}

@MainActor
final class StorageViewModel: ObservableObject {
    @Published var categoryResults: [StorageCategory: [ScannedFile]] = [:]
    @Published var suggestions: [CleanupSuggestion] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = ""
    @Published var selectedCategory: StorageCategory?
    @Published var detailViewMode: DetailViewMode = .byType
    @Published var isCleaningUp: Bool = false
    @Published var cleanupMessage: String = ""
    @Published var selectedFolders: Set<URL> = []
    @Published var scanCurrentCategory: String = ""
    @Published var scanFileCount: Int = 0
    @Published var scanCategoryIndex: Int = 0
    @Published var scanCategoryTotal: Int = 0

    /// Which categories to include in the scan — user can toggle these
    @Published var enabledCategories: Set<StorageCategory> = Set(
        StorageCategory.allCases.filter { $0 != .applications && $0 != .system }
    )

    @AppStorage("fullDiskScan") var fullDiskScan: Bool = false

    private let scanner = FileScanner()
    private let suggestionEngine = SuggestionEngine()

    var diskInfo: DiskInfo { DiskInfo.current() }

    var sortedCategories: [(StorageCategory, Int64)] {
        categoryResults.map { (category, files) in
            (category, files.reduce(Int64(0)) { $0 + $1.size })
        }
        .sorted { $0.1 > $1.1 }
    }

    var selectedFiles: [ScannedFile] {
        categoryResults.values.flatMap { $0 }.filter(\.isSelected)
    }

    var selectedFilesTotalSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }

    func toggleCategory(_ category: StorageCategory) {
        if enabledCategories.contains(category) {
            enabledCategories.remove(category)
        } else {
            enabledCategories.insert(category)
        }
    }

    func scan() async {
        isScanning = true
        scanFileCount = 0
        categoryResults = [:]

        let categoriesToScan = Array(enabledCategories).sorted { $0.rawValue < $1.rawValue }
        scanCategoryTotal = categoriesToScan.count

        for (index, category) in categoriesToScan.enumerated() {
            scanCategoryIndex = index
            scanCurrentCategory = category.rawValue
            scanProgress = "Scanning \(category.rawValue)..."

            // Run file I/O off the main thread to prevent UI freezing
            let files: [ScannedFile] = await Task.detached {
                if category == .developer {
                    return await self.scanner.scanDevArtifacts()
                } else {
                    return await self.scanner.scanCategory(category)
                }
            }.value

            categoryResults[category] = files
            scanFileCount += files.count
        }

        scanCategoryIndex = scanCategoryTotal
        scanProgress = "Analyzing suggestions..."

        // Run suggestion engine off main thread — duplicate detection is heavy
        let currentResults = categoryResults
        let appScanner = AppScanner()
        let generatedSuggestions = await Task.detached { [suggestionEngine] in
            let installedApps = await appScanner.scanAll(includeSystem: false)
            let appNames = Set(installedApps.map(\.name))
            return suggestionEngine.generateAll(files: currentResults, installedAppNames: appNames)
        }.value

        suggestions = generatedSuggestions
        isScanning = false
        scanProgress = ""
    }

    func filesForCategory(_ category: StorageCategory) -> [ScannedFile] {
        categoryResults[category] ?? []
    }

    func categorySize(_ category: StorageCategory) -> Int64 {
        (categoryResults[category] ?? []).reduce(0) { $0 + $1.size }
    }

    func categoryFileCount(_ category: StorageCategory) -> Int {
        (categoryResults[category] ?? []).count
    }

    /// Group files by their top-level subfolder within the category directory
    func groupFilesByFolder(_ files: [ScannedFile], category: StorageCategory) -> [FolderGroupResult] {
        let baseDir = category.directories.first ?? FileManager.default.homeDirectoryForCurrentUser
        let basePath = baseDir.path

        var folderGroups: [String: [ScannedFile]] = [:]
        var rootFiles: [ScannedFile] = []

        for file in files {
            let filePath = file.path.path
            // Get the relative path after the base directory
            if filePath.hasPrefix(basePath) {
                let relative = String(filePath.dropFirst(basePath.count + 1))
                let components = relative.split(separator: "/")
                if components.count > 1 {
                    let topFolder = String(components[0])
                    folderGroups[topFolder, default: []].append(file)
                } else {
                    rootFiles.append(file)
                }
            } else {
                rootFiles.append(file)
            }
        }

        var results: [FolderGroupResult] = folderGroups.map { name, files in
            FolderGroupResult(
                name: name,
                path: baseDir.appending(path: name),
                files: files
            )
        }
        .sorted { $0.totalSize > $1.totalSize }

        // Add root-level files as a group if any
        if !rootFiles.isEmpty {
            results.append(FolderGroupResult(
                name: "Files in \(category.rawValue)",
                path: baseDir,
                files: rootFiles
            ))
        }

        return results
    }

    func groupFilesByType(_ files: [ScannedFile]) -> [TypeGroupResult] {
        let grouped = Dictionary(grouping: files, by: \.typeGroup)
        return grouped.map { TypeGroupResult(type: $0.key, files: $0.value) }
            .sorted { $0.totalSize > $1.totalSize }
    }

    func groupFilesByDate(_ files: [ScannedFile]) -> [DateGroupResult] {
        let grouped = Dictionary(grouping: files, by: \.ageBracket)
        return AgeBracket.allCases.compactMap { bracket in
            guard let files = grouped[bracket], !files.isEmpty else { return nil }
            return DateGroupResult(bracket: bracket, files: files)
        }
    }

    func toggleFileSelection(_ fileID: UUID, in category: StorageCategory) {
        guard var files = categoryResults[category],
              let index = files.firstIndex(where: { $0.id == fileID }) else { return }
        files[index].isSelected.toggle()
        categoryResults[category] = files
    }

    func selectAllInCategory(_ category: StorageCategory) {
        guard var files = categoryResults[category] else { return }
        for i in files.indices { files[i].isSelected = true }
        categoryResults[category] = files
    }

    func deselectAllInCategory(_ category: StorageCategory) {
        guard var files = categoryResults[category] else { return }
        for i in files.indices { files[i].isSelected = false }
        categoryResults[category] = files
    }

    func dismissSuggestion(_ suggestion: CleanupSuggestion) {
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            suggestions[index].isDismissed = true
        }
    }

    var activeSuggestions: [CleanupSuggestion] {
        suggestions.filter { !$0.isDismissed }
    }

    func toggleFolderSelection(_ url: URL) {
        if selectedFolders.contains(url) {
            selectedFolders.remove(url)
        } else {
            selectedFolders.insert(url)
        }
    }

    var selectedFoldersTotalSize: Int64 {
        categoryResults.values.flatMap { $0 }
            .filter { selectedFolders.contains($0.path) }
            .reduce(0) { $0 + $1.size }
    }

    func deleteFolder(at url: URL) async {
        isCleaningUp = true
        cleanupMessage = "Removing \(url.lastPathComponent)..."
        let service = UninstallService()
        do {
            let _ = try await service.uninstall(paths: [url])
        } catch {
            print("Delete folder error: \(error)")
        }
        cleanupMessage = "Done!"
        try? await Task.sleep(for: .seconds(1))
        isCleaningUp = false
        cleanupMessage = ""
        // Don't auto-rescan — user can hit Rescan manually
    }

    func deleteSelectedFolders() async {
        let paths = Array(selectedFolders)
        isCleaningUp = true
        cleanupMessage = "Removing \(paths.count) items..."
        let service = UninstallService()
        do {
            let _ = try await service.uninstall(paths: paths)
        } catch {
            print("Batch delete error: \(error)")
        }
        cleanupMessage = "Done!"
        try? await Task.sleep(for: .seconds(1))
        selectedFolders.removeAll()
        isCleaningUp = false
        cleanupMessage = ""
        // Don't auto-rescan — user can hit Rescan manually
    }

    func cleanupSelected() async {
        isCleaningUp = true
        cleanupMessage = "Cleaning up..."
        let paths = selectedFiles.map(\.path)

        let service = UninstallService()
        do {
            let _ = try await service.uninstall(paths: paths)
        } catch {
            print("Cleanup error: \(error)")
        }

        cleanupMessage = "Done!"
        try? await Task.sleep(for: .seconds(1))
        isCleaningUp = false
        cleanupMessage = ""
        // Don't auto-rescan — user can hit Rescan manually
    }
}
