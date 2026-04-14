import SwiftUI

@main
struct MacUninstallerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environmentObject(appState)
                .onOpenURL { url in
                    handleURL(url)
                }
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
        }
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == AppConstants.urlScheme,
              url.host == "uninstall",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let pathParam = components.queryItems?.first(where: { $0.name == "path" })?.value
        else { return }

        appState.pendingUninstallPath = pathParam
    }
}
