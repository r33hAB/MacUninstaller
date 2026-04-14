import SwiftUI

struct ScannedFileRowView: View {
    let file: ScannedFile
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundStyle(file.isSelected ? AppTheme.accentOrange : AppTheme.borderMedium)
            }
            .buttonStyle(.plain)

            Image(systemName: file.typeGroup.icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(width: 16)

            Text(file.name)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let date = file.dateModified {
                Text(date, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(file.size.formattedFileSize)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
