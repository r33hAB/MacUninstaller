import Cocoa
import FinderSync

class FinderSyncExtension: FIFinderSync {
    override init() {
        super.init()

        let applicationsURL = URL(filePath: "/Applications")
        let userApplicationsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")

        var monitoredDirs = Set<URL>()
        monitoredDirs.insert(applicationsURL)
        if FileManager.default.fileExists(atPath: userApplicationsURL.path) {
            monitoredDirs.insert(userApplicationsURL)
        }

        FIFinderSyncController.default().directoryURLs = monitoredDirs
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }

        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let firstItem = items.first,
              firstItem.pathExtension == "app" else { return nil }

        let menu = NSMenu(title: "")
        let menuItem = NSMenuItem(
            title: "Uninstall with MacUninstaller",
            action: #selector(uninstallApp(_:)),
            keyEquivalent: ""
        )
        menuItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Uninstall")
        menu.addItem(menuItem)
        return menu
    }

    @objc func uninstallApp(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let appURL = items.first else { return }

        let encodedPath = appURL.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(AppConstants.urlScheme)://uninstall?path=\(encodedPath)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
