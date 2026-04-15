import SwiftUI

struct FileTypeGroupView2: View {
    let group: TypeGroupResult
    let category: StorageCategory
    let onToggleFile: (UUID) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: group.type.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.type.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(group.fileCount) files")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Spacer()

                    Text(group.totalSize.formattedFileSize)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.accentOrange)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(12)
                .background(AppTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isExpanded {
                let sorted = group.files.sorted(by: { $0.size > $1.size })
                let maxVisible = 30
                VStack(spacing: 3) {
                    ForEach(sorted.prefix(maxVisible)) { file in
                        ScannedFileRowView(
                            file: file,
                            onToggle: { onToggleFile(file.id) }
                        )
                    }
                    if group.fileCount > maxVisible {
                        let remaining = sorted.dropFirst(maxVisible).reduce(Int64(0)) { $0 + $1.size }
                        Text("+ \(group.fileCount - maxVisible) smaller files (\(remaining.formattedFileSize))")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.leading, 32)
                .padding(.top, 4)
            }
        }
    }
}
