import SwiftUI

struct FileGroupView: View {
    let category: FileCategory
    let files: [AssociatedFile]
    let onToggle: (Int) -> Void
    let globalOffset: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(AppTheme.accentBlue)

            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                HStack(spacing: 10) {
                    Button(action: { onToggle(globalOffset + index) }) {
                        Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 14))
                            .foregroundStyle(file.isSelected ? AppTheme.accentOrange : AppTheme.borderMedium)
                    }
                    .buttonStyle(.plain)

                    Text(file.path.path.replacingOccurrences(
                        of: FileManager.default.homeDirectoryForCurrentUser.path,
                        with: "~"
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                    Spacer()

                    Text(file.size.formattedFileSize)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(8)
                .background(AppTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
