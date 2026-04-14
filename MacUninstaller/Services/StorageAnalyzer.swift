import Foundation

struct DiskInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64

    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }

    static func current() -> DiskInfo {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            return DiskInfo(totalSpace: total, usedSpace: total - free, freeSpace: free)
        }
        return DiskInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
    }
}

struct StorageInsights {
    let totalReclaimableSpace: Int64
    let totalApps: Int
    let appStoreApps: Int
    let unusedApps: [AppInfo]
    let unusedTotalSize: Int64
    let largestApp: AppInfo?
    let diskInfo: DiskInfo
}

final class StorageAnalyzer {
    func analyze(apps: [AppInfo]) -> StorageInsights {
        let totalSpace = apps.reduce(Int64(0)) { $0 + $1.totalSize }
        let appStoreCount = apps.filter { $0.source == .appStore }.count
        let unused = apps.filter { $0.isUnused }
        let unusedSize = unused.reduce(Int64(0)) { $0 + $1.totalSize }
        let largest = apps.max(by: { $0.totalSize < $1.totalSize })

        return StorageInsights(
            totalReclaimableSpace: totalSpace,
            totalApps: apps.count,
            appStoreApps: appStoreCount,
            unusedApps: unused,
            unusedTotalSize: unusedSize,
            largestApp: largest,
            diskInfo: DiskInfo.current()
        )
    }
}
