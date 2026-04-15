import SwiftUI

struct AppRowView: View {
    let app: AppInfo
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? AppTheme.accentOrange : AppTheme.borderMedium)
            }
            .buttonStyle(.plain)

            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.backgroundCard)
                    .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if app.isUnused {
                        Text("UNUSED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(AppTheme.accentRed)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    if app.source == .system {
                        Text("SYSTEM")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(AppTheme.accentRed)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                Text("\(app.bundleIdentifier) · Last used: \(lastUsedText)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.totalSize.formattedFileSize)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentOrange)
                Text("app: \(app.bundleSize.formattedFileSize) · data: \(app.associatedFilesSize.formattedFileSize)")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
                if isContainerHeavy {
                    Text("Includes VM/container data")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.accentBlue)
                }
            }
            .padding(.trailing, 16)

            Button("Uninstall", action: onUninstall)
                .buttonStyle(GradientButtonStyle())
        }
        .padding(12)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    app.isUnused ? AppTheme.accentRed.opacity(0.2) : AppTheme.backgroundCard,
                    lineWidth: 1
                )
        )
    }

    private var isContainerHeavy: Bool {
        AppConstants.containerHeavyApps.contains(app.bundleIdentifier)
            && app.associatedFilesSize > 1_000_000_000 // > 1 GB data
    }

    private var lastUsedText: String {
        guard let date = app.lastUsedDate else { return "Never" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }
}
