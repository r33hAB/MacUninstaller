import SwiftUI

@main
struct MacUninstallerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("MacUninstaller")
                .frame(minWidth: 900, minHeight: 600)
                .background(AppTheme.backgroundPrimary)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
