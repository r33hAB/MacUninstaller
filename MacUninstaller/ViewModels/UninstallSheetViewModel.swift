import SwiftUI

@MainActor
final class UninstallSheetViewModel: ObservableObject {
    let app: AppInfo
    @Published var files: [AssociatedFile]
    @Published var includeAppBundle: Bool = true

    init(app: AppInfo) {
        self.app = app
        self.files = app.associatedFiles.map { file in
            var f = file
            f.isSelected = true
            return f
        }
    }

    var totalSelectedSize: Int64 {
        let filesSize = files.filter(\.isSelected).reduce(Int64(0)) { $0 + $1.size }
        return (includeAppBundle ? app.bundleSize : 0) + filesSize
    }

    var associatedFilesSelectedSize: Int64 {
        files.filter(\.isSelected).reduce(Int64(0)) { $0 + $1.size }
    }

    var filesByCategory: [(category: FileCategory, files: [AssociatedFile])] {
        let grouped = Dictionary(grouping: files, by: \.category)
        return grouped
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (category: $0.key, files: $0.value) }
    }

    var hasAdminFiles: Bool {
        files.contains { $0.requiresAdmin && $0.isSelected }
    }

    var selectedPaths: [URL] {
        var paths: [URL] = []
        if includeAppBundle {
            paths.append(app.bundlePath)
        }
        paths.append(contentsOf: files.filter(\.isSelected).map(\.path))
        return paths
    }

    func toggleFile(at index: Int) {
        files[index].isSelected.toggle()
    }

    func selectAll() {
        for i in files.indices {
            files[i].isSelected = true
        }
        includeAppBundle = true
    }

    func deselectAll() {
        for i in files.indices {
            files[i].isSelected = false
        }
        includeAppBundle = false
    }
}
