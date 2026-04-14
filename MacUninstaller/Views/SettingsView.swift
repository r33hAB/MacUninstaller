import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    private let sipChecker = SIPChecker()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("General")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Toggle("Launch at login", isOn: $viewModel.launchAtLogin)
                        .foregroundStyle(AppTheme.textPrimary)

                    Toggle("Move to Trash (uncheck for permanent delete)", isOn: $viewModel.useTrash)
                        .foregroundStyle(AppTheme.textPrimary)

                    Toggle("Finder extension enabled", isOn: $viewModel.finderExtensionEnabled)
                        .foregroundStyle(AppTheme.textPrimary)

                    Toggle("Full disk scanning (shows system files)", isOn: $viewModel.fullDiskScan)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(16)
                .cardStyle()

                RiskyModeView(
                    viewModel: viewModel,
                    sipEnabled: sipChecker.isSIPEnabled()
                )
            }
            .padding(24)
        }
        .frame(width: 500, height: 450)
        .background(AppTheme.backgroundPrimary)
    }
}
