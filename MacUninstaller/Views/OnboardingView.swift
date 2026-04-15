import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text("\u{26A1}")
                            .font(.system(size: 30))
                    )
                    .padding(.top, 28)

                Text("Welcome to MacUninstaller")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Two quick permissions to unlock full power.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 24)

            Divider().background(AppTheme.borderLight)

            // Pages
            if currentPage == 0 {
                permissionPage(
                    icon: "appclip",
                    title: "APP MANAGEMENT",
                    description: "Allows MacUninstaller to remove apps without asking for your password every time. Grant once, works forever.",
                    steps: [
                        "Click the button below to open Settings",
                        "Find MacUninstaller in the list",
                        "Toggle it on"
                    ],
                    buttonTitle: "Open App Management Settings",
                    action: {
                        // Open Privacy & Security > App Management
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            } else {
                permissionPage(
                    icon: "folder.badge.gearshape",
                    title: "FINDER INTEGRATION",
                    description: "Adds \"Uninstall with MacUninstaller\" to the right-click menu on any app in Finder.",
                    steps: [
                        "Click the button below to open Settings",
                        "Find MacUninstaller under Finder Extensions",
                        "Toggle it on"
                    ],
                    buttonTitle: "Open Finder Extension Settings",
                    action: {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.extensions?Finder") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            }

            Divider().background(AppTheme.borderLight)

            // Navigation
            HStack(spacing: 12) {
                if currentPage == 0 {
                    Button("Skip All") {
                        hasSeenOnboarding = true
                        isPresented = false
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .buttonStyle(.plain)
                } else {
                    Button(action: { withAnimation { currentPage = 0 } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10))
                            Text("Back")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Page dots
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentPage == 0 ? AppTheme.accentOrange : AppTheme.textTertiary)
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(currentPage == 1 ? AppTheme.accentOrange : AppTheme.textTertiary)
                        .frame(width: 6, height: 6)
                }

                Spacer()

                if currentPage == 0 {
                    Button(action: { withAnimation { currentPage = 1 } }) {
                        Text("Next")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(GradientButtonStyle())
                } else {
                    Button(action: {
                        hasSeenOnboarding = true
                        isPresented = false
                    }) {
                        Text("Get Started")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(GradientButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 420)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func permissionPage(
        icon: String,
        title: String,
        description: String,
        steps: [String],
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accentOrange)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Circle())

                        Text(step)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }

            Button(action: action) {
                HStack {
                    Image(systemName: "gearshape")
                    Text(buttonTitle)
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
    }
}
