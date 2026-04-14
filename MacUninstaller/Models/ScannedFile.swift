import Foundation
import SwiftUI

enum FileTypeGroup: String, CaseIterable, Identifiable {
    case apps = "Applications"
    case installers = "Installers & Disk Images"
    case videos = "Videos"
    case archives = "Archives & Packages"
    case documents = "Documents & PDFs"
    case images = "Images"
    case code = "Code & Scripts"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .apps: return "square.stack.3d.up.fill"
        case .installers: return "opticaldisc.fill"
        case .videos: return "film"
        case .archives: return "archivebox.fill"
        case .documents: return "doc.text.fill"
        case .images: return "photo"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .other: return "doc.fill"
        }
    }

    static func from(extension ext: String) -> FileTypeGroup {
        let lower = ext.lowercased()
        switch lower {
        case "app": return .apps
        case "dmg", "pkg", "iso": return .installers
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v": return .videos
        case "zip", "tar", "gz", "rar", "7z", "bz2", "xz", "tgz": return .archives
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "keynote", "txt", "rtf", "csv": return .documents
        case "png", "jpg", "jpeg", "gif", "svg", "heic", "webp", "tiff", "bmp", "ico", "raw": return .images
        case "py", "js", "ts", "jsx", "tsx", "swift", "sh", "json", "yaml", "yml", "xml", "html", "css", "rb", "go", "rs", "java", "kt", "c", "cpp", "h", "m": return .code
        default: return .other
        }
    }
}

enum AgeBracket: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 days"
    case last30Days = "Last 30 days"
    case oneToSixMonths = "1 – 6 months ago"
    case olderThan6Months = "Older than 6 months"

    var id: String { rawValue }

    var color: SwiftUI.Color {
        switch self {
        case .last7Days: return SwiftUI.Color(hex: 0x3B82F6)
        case .last30Days: return SwiftUI.Color(hex: 0x22C55E)
        case .oneToSixMonths: return SwiftUI.Color(hex: 0xF59E0B)
        case .olderThan6Months: return SwiftUI.Color(hex: 0xEF4444)
        }
    }

    var isStale: Bool { self == .olderThan6Months }

    static func from(date: Date?) -> AgeBracket {
        guard let date else { return .olderThan6Months }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days <= 7 { return .last7Days }
        if days <= 30 { return .last30Days }
        if days <= 180 { return .oneToSixMonths }
        return .olderThan6Months
    }
}

struct ScannedFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let dateModified: Date?
    let dateAccessed: Date?
    let category: StorageCategory
    var isSelected: Bool = false

    var name: String { path.lastPathComponent }
    var typeGroup: FileTypeGroup { FileTypeGroup.from(extension: path.pathExtension) }
    var ageBracket: AgeBracket { AgeBracket.from(date: dateModified) }
    var isLarge: Bool { size > 500_000_000 }
    var isStale: Bool { ageBracket.isStale }
}
