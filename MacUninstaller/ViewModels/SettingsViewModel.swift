import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("useTrash") var useTrash: Bool = true
    @AppStorage("finderExtensionEnabled") var finderExtensionEnabled: Bool = true
    @AppStorage("riskyModeUnlocked") var riskyModeUnlocked: Bool = false
    @AppStorage("riskyModeEnabled") var riskyModeEnabled: Bool = false
    @AppStorage("fullDiskScan") var fullDiskScan: Bool = false

    @Published var unlockText: String = ""

    var isRiskyModeAvailable: Bool {
        riskyModeUnlocked
    }

    func attemptUnlock() -> Bool {
        if unlockText.lowercased().trimmingCharacters(in: .whitespaces) == "i understand" {
            riskyModeUnlocked = true
            return true
        }
        return false
    }
}
