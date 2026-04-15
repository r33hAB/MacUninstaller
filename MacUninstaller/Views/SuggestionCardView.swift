import SwiftUI

struct SuggestionCardView: View {
    let suggestion: CleanupSuggestion
    let onReview: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(suggestion.type.color)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Text(suggestion.type.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("\(suggestion.fileCount) files · \(suggestion.type.description)")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(2)

            Spacer()

            HStack {
                Text(suggestion.totalSize.formattedFileSize)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(AppTheme.accentOrange)
                Spacer()
                Button("Review", action: onReview)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 180, height: 140)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
    }
}
