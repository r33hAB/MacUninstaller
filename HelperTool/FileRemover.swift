import Foundation

final class FileRemover {
    private let fileManager = FileManager.default

    private let blockedPaths: Set<String> = [
        "/System/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/Library/Apple",
    ]

    func remove(paths: [String], useTrash: Bool) -> (success: Bool, error: String?) {
        var errors: [String] = []

        for path in paths {
            let isBlocked = blockedPaths.contains { path.hasPrefix($0) }
            if isBlocked {
                errors.append("Blocked path: \(path)")
                continue
            }

            do {
                if useTrash {
                    let url = URL(filePath: path)
                    var trashedURL: NSURL?
                    try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)
                } else {
                    try fileManager.removeItem(atPath: path)
                }
            } catch {
                errors.append("\(path): \(error.localizedDescription)")
            }
        }

        if errors.isEmpty {
            return (true, nil)
        } else {
            return (false, errors.joined(separator: "\n"))
        }
    }
}
