import SwiftUI

struct RiskyModeView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showUnlockField = false
    @State private var unlockFailed = false

    let sipEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.riskyModeUnlocked {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Allow system app removal", isOn: $viewModel.riskyModeEnabled)
                        .foregroundStyle(AppTheme.textPrimary)

                    if viewModel.riskyModeEnabled && sipEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.accentOrange)
                            Text("System Integrity Protection is enabled. Some system apps cannot be removed until SIP is disabled.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(16)
                .background(AppTheme.dangerBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.dangerBorder, lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("System app removal is locked. This feature allows removing native macOS apps and may break OS functionality.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)

                    if showUnlockField {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type \"I understand\" to unlock:")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textTertiary)
                            HStack {
                                TextField("", text: $viewModel.unlockText)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(AppTheme.backgroundPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Button("Unlock") {
                                    if !viewModel.attemptUnlock() {
                                        unlockFailed = true
                                    }
                                }
                                .buttonStyle(GradientButtonStyle())
                            }
                            if unlockFailed {
                                Text("Incorrect. Type exactly: I understand")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.accentRed)
                            }
                        }
                    } else {
                        Button("Unlock Risky Mode") {
                            showUnlockField = true
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.accentRed)
                        .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(16)
                .background(AppTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.borderLight, lineWidth: 1)
                )
            }
        }
    }
}
