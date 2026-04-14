import SwiftUI

enum AppFilter: String, CaseIterable {
    case all = "All Apps"
    case largest = "Largest"
    case unused = "Unused"
    case appStore = "App Store"
    case system = "System"
}

enum SortOption: String, CaseIterable {
    case size = "Size"
    case name = "Name"
    case lastUsed = "Last Used"
    case installDate = "Install Date"
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @AppStorage("riskyModeEnabled") var riskyModeEnabled: Bool = false
    @Published var allApps: [AppInfo] = []
    @Published var activeFilter: AppFilter = .all
    @Published var sortOption: SortOption = .size
    @Published var searchText: String = ""
    @Published var selectedAppIDs: Set<UUID> = []
    @Published var isLoading: Bool = false
    @Published var appToUninstall: AppInfo?
    @Published var showBatchConfirm: Bool = false
    @Published var isUninstalling: Bool = false
    @Published var uninstallProgress: String = ""
    @Published var uninstallCurrentIndex: Int = 0
    @Published var uninstallTotalCount: Int = 0
    @Published var uninstallAppNames: [String] = []

    private let scanner = AppScanner()
    private let fileFinder = FileFinder()
    private let storageAnalyzer = StorageAnalyzer()

    var insights: StorageInsights {
        storageAnalyzer.analyze(apps: allApps)
    }

    var filteredApps: [AppInfo] {
        var apps = allApps

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            apps = apps.filter {
                $0.name.lowercased().contains(query)
                || $0.bundleIdentifier.lowercased().contains(query)
            }
        }

        switch activeFilter {
        case .all:
            break
        case .largest:
            break
        case .unused:
            apps = apps.filter { $0.isUnused }
        case .appStore:
            apps = apps.filter { $0.source == .appStore }
        case .system:
            apps = apps.filter { $0.source == .system }
        }

        switch sortOption {
        case .size:
            apps.sort { $0.totalSize > $1.totalSize }
        case .name:
            apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .lastUsed:
            apps.sort { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) }
        case .installDate:
            apps.sort { ($0.installDate ?? .distantPast) > ($1.installDate ?? .distantPast) }
        }

        return apps
    }

    var selectedAppsCount: Int {
        selectedAppIDs.count
    }

    func selectAll() {
        selectedAppIDs = Set(filteredApps.map(\.id))
    }

    func deselectAll() {
        selectedAppIDs.removeAll()
    }

    func toggleSelection(for app: AppInfo) {
        if selectedAppIDs.contains(app.id) {
            selectedAppIDs.remove(app.id)
        } else {
            selectedAppIDs.insert(app.id)
        }
    }

    func loadApps() async {
        await loadApps(includeSystem: riskyModeEnabled)
    }

    func loadApps(includeSystem: Bool) async {
        isLoading = true
        allApps = await scanner.scanAll(includeSystem: includeSystem)

        for i in allApps.indices {
            allApps[i].associatedFiles = await fileFinder.findAssociatedFiles(
                bundleIdentifier: allApps[i].bundleIdentifier,
                appPath: allApps[i].bundlePath
            )
        }

        isLoading = false
    }

    var selectedApps: [AppInfo] {
        allApps.filter { selectedAppIDs.contains($0.id) }
    }

    func prepareUninstall(app: AppInfo) {
        appToUninstall = app
    }

    func prepareBatchUninstall() {
        showBatchConfirm = true
    }

    func executeBatchUninstall() async {
        let apps = selectedApps
        uninstallAppNames = apps.map(\.name)
        uninstallTotalCount = apps.count
        uninstallCurrentIndex = 0
        isUninstalling = true

        let service = UninstallService()

        // Collect ALL paths but track per-app for progress display
        var allPaths: [URL] = []
        for app in apps {
            allPaths.append(app.bundlePath)
            allPaths.append(contentsOf: app.associatedFiles.map(\.path))
        }

        // Show progress through app names while the single batch runs
        // Start a timer to cycle through names
        let progressTask = Task { @MainActor in
            for i in 0..<apps.count {
                uninstallCurrentIndex = i
                uninstallProgress = "Removing \(apps[i].name)..."
                try? await Task.sleep(for: .milliseconds(800))
            }
        }

        do {
            let _ = try await service.uninstall(paths: allPaths)
        } catch {
            print("Batch uninstall error: \(error)")
        }

        progressTask.cancel()
        uninstallCurrentIndex = uninstallTotalCount
        uninstallProgress = "Done!"

        try? await Task.sleep(for: .seconds(1))

        isUninstalling = false
        uninstallProgress = ""
        uninstallAppNames = []
        selectedAppIDs.removeAll()

        // Refresh in background — user sees the list update naturally
        await loadApps()
    }
}
