import Foundation
import AppKit

final class AppScanner {
    private let fileManager = FileManager.default

    func scanAll(includeSystem: Bool) async -> [AppInfo] {
        var seen = Set<String>() // deduplicate by bundle ID
        var apps: [AppInfo] = []

        // 1. Use Launch Services to find ALL registered apps on the system
        //    This catches apps in non-standard locations (Steam, Homebrew, etc.)
        let lsApps = scanLaunchServices(includeSystem: includeSystem)
        for app in lsApps {
            if seen.insert(app.bundleIdentifier).inserted {
                apps.append(app)
            }
        }

        // 2. Also scan standard directories for apps that might not be in LS database
        let directories: [URL] = [
            URL(filePath: "/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        // 3. Common non-standard app locations
        let extraDirs: [URL] = [
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/Steam/steamapps/common"),
            URL(filePath: "/opt/homebrew/Caskroom"),
            URL(filePath: "/usr/local/Caskroom"),
        ]

        for dir in directories + extraDirs {
            let found = await scanDirectoryRecursive(dir)
            for app in found {
                if !includeSystem && app.source == .system { continue }
                if seen.insert(app.bundleIdentifier).inserted {
                    apps.append(app)
                }
            }
        }

        // 4. System apps if requested
        if includeSystem {
            let systemApps = await scanDirectoryRecursive(URL(filePath: "/System/Applications"))
            for app in systemApps {
                if seen.insert(app.bundleIdentifier).inserted {
                    let systemApp = AppInfo(
                        name: app.name,
                        bundleIdentifier: app.bundleIdentifier,
                        bundlePath: app.bundlePath,
                        icon: app.icon,
                        bundleSize: app.bundleSize,
                        source: .system,
                        installDate: app.installDate,
                        lastUsedDate: app.lastUsedDate,
                        isAdminOwned: true
                    )
                    apps.append(systemApp)
                }
            }
        }

        return apps
    }

    /// Query macOS Launch Services for all registered applications
    private func scanLaunchServices(includeSystem: Bool) -> [AppInfo] {
        var results: [AppInfo] = []

        guard let appURLs = LSCopyApplicationURLsForURL(
            URL(string: "https://example.com")! as CFURL, .all
        ) else {
            // Fallback: use workspace to get all apps
            return scanWorkspaceApps(includeSystem: includeSystem)
        }

        // Actually, LSCopyApplicationURLsForURL only gets apps for a specific URL type.
        // Use the workspace approach which is more comprehensive.
        return scanWorkspaceApps(includeSystem: includeSystem)
    }

    /// Use NSWorkspace to find all applications via Spotlight
    private func scanWorkspaceApps(includeSystem: Bool) -> [AppInfo] {
        var results: [AppInfo] = []

        // Use mdfind to query Spotlight for all .app bundles
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemContentType == 'com.apple.application-bundle'"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let paths = output.components(separatedBy: "\n").filter { !$0.isEmpty }

            for path in paths {
                let url = URL(filePath: path)

                // Skip system apps unless requested
                if !includeSystem && url.path.hasPrefix("/System/") { continue }

                if let appInfo = readAppInfo(at: url) {
                    results.append(appInfo)
                }
            }
        } catch {
            print("mdfind failed: \(error)")
        }

        return results
    }

    /// Check if a nested .app is in a known directory where standalone apps live
    private func isKnownAppDirectory(_ url: URL) -> Bool {
        let path = url.path
        return path.contains("/Steam/steamapps/common/")
            || path.contains("/GOG Games/")
            || path.contains("/Epic Games/")
            || path.contains("/itch/")
            || path.contains("/Caskroom/")
    }

    func scanDirectory(_ directory: URL) async -> [AppInfo] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var results: [AppInfo] = []
        for url in contents where url.pathExtension == "app" {
            if let appInfo = readAppInfo(at: url) {
                results.append(appInfo)
            }
        }
        return results
    }

    /// Recursively scan directory for .app bundles (for Steam, Homebrew, etc.)
    private func scanDirectoryRecursive(_ directory: URL) async -> [AppInfo] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }

        var results: [AppInfo] = []

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                if let appInfo = readAppInfo(at: url) {
                    results.append(appInfo)
                }
                enumerator.skipDescendants() // don't scan inside .app bundles
            }
        }

        return results
    }

    /// Filter out system helpers, agents, daemons, droplets, and internal tools
    private func isUserFacingApp(bundle: Bundle, url: URL) -> Bool {
        let path = url.path
        let bundleID = bundle.bundleIdentifier ?? ""
        let info = bundle.infoDictionary ?? [:]

        // Skip things in system/internal directories
        let skipPrefixes = [
            "/System/",
            "/Library/Apple/",
            "/Library/Developer/",
            "/usr/",
            "/private/",
            "/Library/Application Support/",
            "/Library/Frameworks/",
            "/Library/CoreMediaIO/",
            "/Library/Image Capture/",
            "/Library/Printers/",
            "/Library/Screen Savers/",
            "/Library/PreferencePanes/",
        ]
        for prefix in skipPrefixes {
            if path.hasPrefix(prefix) { return false }
        }

        // Skip if inside another app's bundle (Xcode tools, etc.)
        let components = url.pathComponents
        let appCount = components.filter { $0.hasSuffix(".app") }.count
        if appCount > 1 && !isKnownAppDirectory(url) { return false }

        // Skip background agents and daemons (no UI)
        if let bgOnly = info["LSBackgroundOnly"] as? Bool, bgOnly { return false }
        if let bgOnly = info["LSBackgroundOnly"] as? String, bgOnly == "1" { return false }
        if let uiElement = info["LSUIElement"] as? Bool, uiElement { return false }
        if let uiElement = info["LSUIElement"] as? String, uiElement == "1" { return false }

        // Skip Automator droplets and actions
        let name = url.deletingPathExtension().lastPathComponent
        if name.contains("Droplet") || name.contains("Automator") { return false }
        if bundleID.hasPrefix("com.apple.automator") { return false }

        // Skip URL handlers, helpers, updaters with tiny size (< 1 MB)
        let tinyApp = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int ?? 0
        let isTiny = tinyApp < 1_000_000
        let helperNames = ["helper", "updater", "agent", "daemon", "handler", "launcher", "installer", "uninstaller", "migrator", "crash"]
        let lowerName = name.lowercased()
        if isTiny && helperNames.contains(where: { lowerName.contains($0) }) { return false }

        // Skip known system/internal bundle ID prefixes
        let skipBundlePrefixes = [
            "com.apple.dt.",         // Xcode dev tools
            "com.apple.ScriptEditor", // Script internals
            "com.apple.print.",      // Print system
            "com.apple.ScreenSaver.", // Screen savers
        ]
        for prefix in skipBundlePrefixes {
            if bundleID.hasPrefix(prefix) { return false }
        }

        // Skip apps in ~/Library (except known app directories)
        if path.contains("/Library/") && !isKnownAppDirectory(url)
            && !path.hasPrefix("/Applications") {
            // Allow ~/Library/Application Support/Steam/
            if !path.contains("/Steam/") { return false }
        }

        return true
    }

    private func readAppInfo(at url: URL) -> AppInfo? {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return nil }

        // Filter out non-user-facing apps
        if !isUserFacingApp(bundle: bundle, url: url) { return nil }

        let name = bundle.infoDictionary?["CFBundleName"] as? String
            ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        let bundleSize = directorySize(url)
        let isAdmin = isAdminOwned(url)

        let installDate = spotlightDate(for: url, attribute: "kMDItemDateAdded")
        let lastUsed = spotlightDate(for: url, attribute: "kMDItemLastUsedDate")

        let source: AppSource = url.path.hasPrefix("/System/Applications")
            ? .system
            : detectAppStoreApp(bundleID: bundleID, appURL: url) ? .appStore : .manual

        return AppInfo(
            name: name,
            bundleIdentifier: bundleID,
            bundlePath: url,
            icon: icon,
            bundleSize: bundleSize,
            source: source,
            installDate: installDate,
            lastUsedDate: lastUsed,
            isAdminOwned: isAdmin
        )
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if values?.isDirectory == false {
                total += Int64(values?.fileSize ?? 0)
            }
        }
        return total
    }

    private func isAdminOwned(_ url: URL) -> Bool {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let ownerID = attrs[.ownerAccountID] as? NSNumber else { return false }
        return ownerID.intValue == 0
    }

    private func spotlightDate(for url: URL, attribute: String) -> Date? {
        let item = MDItemCreateWithURL(nil, url as CFURL)
        guard let item else { return nil }
        return MDItemCopyAttribute(item, attribute as CFString) as? Date
    }

    private func detectAppStoreApp(bundleID: String, appURL: URL) -> Bool {
        let receiptURL = appURL.appendingPathComponent("Contents/_MASReceipt/receipt")
        return fileManager.fileExists(atPath: receiptURL.path)
    }
}
