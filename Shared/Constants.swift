import Foundation

enum AppConstants {
    static let appBundleID = "io.darevader.MacUninstaller"
    static let helperBundleID = "io.darevader.MacUninstaller.HelperTool"
    static let extensionBundleID = "io.darevader.MacUninstaller.FinderExtension"
    static let urlScheme = "macuninstaller"

    static let blockedPaths: Set<String> = [
        "/System/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/Library/Apple",
    ]

    static let librarySearchPaths: [String] = [
        "Application Support",
        "Preferences",
        "Caches",
        "Containers",
        "Group Containers",
        "Saved Application State",
        "Logs",
        "HTTPStorages",
        "WebKit",
    ]

    static let systemLibrarySearchPaths: [String] = [
        "Application Support",
        "Preferences",
        "LaunchAgents",
        "LaunchDaemons",
    ]

    static let unusedThresholdDays: Int = 90
}
