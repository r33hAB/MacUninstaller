import Foundation

enum AppConstants {
    static let appBundleID = "com.r33hab.macuninstall"
    static let helperBundleID = "com.r33hab.macuninstall.HelperTool"
    static let extensionBundleID = "com.r33hab.macuninstall.FinderExtension"

    /// Apps known to have large container data (VMs, images, etc.)
    /// that shouldn't alarm users with their total size
    static let containerHeavyApps: Set<String> = [
        "com.docker.docker",
        "com.parallels.desktop.console",
        "com.vmware.fusion",
        "com.utmapp.UTM",
    ]
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
