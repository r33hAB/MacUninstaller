import SwiftUI

enum PermissionTier: Equatable {
    case standard
    case adminRequired
    case system
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let bundlePath: URL
    let icon: NSImage?
    let bundleSize: Int64
    let source: AppSource
    let installDate: Date?
    let lastUsedDate: Date?
    var isAdminOwned: Bool = false
    var associatedFiles: [AssociatedFile] = []

    var totalSize: Int64 {
        bundleSize + associatedFilesSize
    }

    var associatedFilesSize: Int64 {
        associatedFiles.reduce(0) { $0 + $1.size }
    }

    var isUnused: Bool {
        guard let lastUsed = lastUsedDate else { return true }
        let daysSinceUse = Calendar.current.dateComponents(
            [.day], from: lastUsed, to: Date()
        ).day ?? 0
        return daysSinceUse >= AppConstants.unusedThresholdDays
    }

    var permissionTier: PermissionTier {
        if source == .system { return .system }
        if isAdminOwned { return .adminRequired }
        return .standard
    }
}
