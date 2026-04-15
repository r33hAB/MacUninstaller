import AppKit

class ServiceHandler: NSObject {
    @objc func uninstallApp(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let appURL = urls.first else {
            // Try reading file paths as strings
            guard let items = pboard.pasteboardItems,
                  let path = items.first?.string(forType: .fileURL),
                  let url = URL(string: path) else { return }
            openForUninstall(url)
            return
        }
        openForUninstall(appURL)
    }

    private func openForUninstall(_ url: URL) {
        let encodedPath = url.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(AppConstants.urlScheme)://uninstall?path=\(encodedPath)"
        if let launchURL = URL(string: urlString) {
            NSWorkspace.shared.open(launchURL)
        }
    }
}
