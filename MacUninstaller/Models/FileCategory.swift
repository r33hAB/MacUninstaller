import Foundation

enum FileCategory: String, CaseIterable, Identifiable {
    case appBundle = "App Bundle"
    case applicationSupport = "Application Support"
    case preferences = "Preferences"
    case caches = "Caches"
    case savedState = "Saved State"
    case logs = "Logs"
    case httpStorages = "HTTP Storage"
    case webKit = "WebKit"
    case launchAgents = "Launch Agents"
    case launchDaemons = "Launch Daemons"

    var id: String { rawValue }
}
