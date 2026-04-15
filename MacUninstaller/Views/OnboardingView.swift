import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text("\u{26A1}")
                            .font(.system(size: 30))
                    )
                    .padding(.top, 32)

                Text("Welcome to MacUninstaller")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Clean your Mac completely \u{2014} apps, caches, and junk files.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)

            Divider().background(AppTheme.borderLight)

            // Finder Extension setup
            VStack(alignment: .leading, spacing: 16) {
                Text("ENABLE FINDER INTEGRATION")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AppTheme.textTertiary)

                Text("Right-click any app in Finder to uninstall it instantly.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    stepRow(number: "1", text: "Open System Settings")
                    stepRow(number: "2", text: "Go to Privacy & Security \u{2192} Extensions")
                    stepRow(number: "3", text: "Enable MacUninstaller under Finder")
                }

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
                }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Open System Settings")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.backgroundCard)
                    .foregroundStyle(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.borderLight, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider().background(AppTheme.borderLight)

            // Buttons
            HStack(spacing: 12) {
                Button("Skip") {
                    hasSeenOnboarding = true
                    isPresented = false
                }
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    hasSeenOnboarding = true
                    isPresented = false
                }) {
                    Text("Get Started")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GradientButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 400)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.primaryGradient)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
