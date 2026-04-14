import SwiftUI

struct StorageCategoryRowView: View {
    let category: StorageCategory
    let size: Int64
    let fileCount: Int
    let badge: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(category.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category == .caches ? AppTheme.accentRed : AppTheme.accentOrange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    Text("\(fileCount) files")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()

                Text(size.formattedFileSize)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(category.color)

                if category != .system {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(category == .system || category == .applications)
    }
}
