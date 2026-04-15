import SwiftUI

enum StorageCategory: String, CaseIterable, Identifiable {
    case applications = "Applications"
    case documents = "Documents"
    case downloads = "Downloads"
    case developer = "Developer"
    case music = "Music & Audio"
    case photos = "Photos & Videos"
    case caches = "Caches & Logs"
    case other = "Other"
    case system = "System"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .applications: return "square.stack.3d.up.fill"
        case .documents: return "doc.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .music: return "music.note"
        case .photos: return "photo.fill"
        case .caches: return "internaldrive.fill"
        case .other: return "folder.fill"
        case .system: return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .applications: return Color(hex: 0x3B82F6)
        case .documents: return AppTheme.accentOrange
        case .downloads: return Color(hex: 0xF59E0B)
        case .developer: return Color(hex: 0x8B5CF6)
        case .music: return Color(hex: 0x22C55E)
        case .photos: return Color(hex: 0xEC4899)
        case .caches: return Color(hex: 0x6B7280)
        case .other: return Color(hex: 0x4B5563)
        case .system: return Color(hex: 0x6B7280)
        }
    }

    var directories: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .applications: return []
        case .documents: return [home.appending(path: "Documents")]
        case .downloads: return [home.appending(path: "Downloads")]
        case .developer: return []
        case .music: return [home.appending(path: "Music")]
        case .photos: return [home.appending(path: "Pictures"), home.appending(path: "Movies")]
        case .caches: return [home.appending(path: "Library/Caches"), home.appending(path: "Library/Logs")]
        case .other: return [home.appending(path: "Desktop")]
        case .system: return []
        }
    }
}
