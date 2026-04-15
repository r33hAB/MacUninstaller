import SwiftUI

enum SuggestionType: String, Identifiable {
    case oldInstallers = "Old Installers"
    case duplicates = "Duplicate Files"
    case nearDuplicates = "Near-Duplicates"
    case extractedArchives = "Extracted Archives"
    case staleDownloads = "Stale Downloads"
    case largeFiles = "Large Files"
    case devArtifacts = "Dev Artifacts"
    case oldScreenshots = "Old Screenshots"
    case cacheBloat = "Cache Bloat"
    case brokenSymlinks = "Broken Symlinks"
    case appsInDownloads = "Apps in Downloads"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .oldInstallers: return "opticaldisc.fill"
        case .duplicates: return "doc.on.doc.fill"
        case .nearDuplicates: return "doc.on.doc"
        case .extractedArchives: return "archivebox.fill"
        case .staleDownloads: return "clock.arrow.circlepath"
        case .largeFiles: return "exclamationmark.triangle.fill"
        case .devArtifacts: return "hammer.fill"
        case .oldScreenshots: return "camera.fill"
        case .cacheBloat: return "internaldrive.fill"
        case .brokenSymlinks: return "link"
        case .appsInDownloads: return "arrow.right.square"
        }
    }

    var color: Color {
        switch self {
        case .oldInstallers, .extractedArchives, .brokenSymlinks: return AppTheme.accentOrange
        case .duplicates, .nearDuplicates: return Color(hex: 0x8B5CF6)
        case .staleDownloads, .oldScreenshots: return AppTheme.accentRed
        case .largeFiles: return Color(hex: 0xF59E0B)
        case .devArtifacts: return Color(hex: 0x667EEA)
        case .cacheBloat: return Color(hex: 0x6B7280)
        case .appsInDownloads: return Color(hex: 0x3B82F6)
        }
    }

    var description: String {
        switch self {
        case .oldInstallers: return "DMGs/PKGs from apps already installed"
        case .duplicates: return "Exact duplicate files wasting space"
        case .nearDuplicates: return "Files with copy/duplicate suffixes"
        case .extractedArchives: return "ZIP files sitting next to extracted folders"
        case .staleDownloads: return "Downloads not opened in 6+ months"
        case .largeFiles: return "Files over 500 MB worth reviewing"
        case .devArtifacts: return "Regenerable build artifacts"
        case .oldScreenshots: return "Screenshots on Desktop older than 30 days"
        case .cacheBloat: return "App caches over 500 MB each"
        case .brokenSymlinks: return "Symlinks pointing to deleted files"
        case .appsInDownloads: return "App bundles that should be in /Applications"
        }
    }
}

struct CleanupSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let files: [ScannedFile]
    var isDismissed: Bool = false

    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }
    var fileCount: Int { files.count }
}
