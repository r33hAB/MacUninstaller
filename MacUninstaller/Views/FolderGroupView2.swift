import SwiftUI

struct FolderGroupView2: View {
    let group: FolderGroupResult
    let category: StorageCategory
    let onToggleFile: (UUID) -> Void
    let onDeleteFolder: (URL) -> Void
    let isChecked: Bool
    let onToggleCheck: () -> Void
    @State private var isExpanded = false
    @State private var showDeleteConfirm = false

    private let maxVisible = 30

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Batch selection checkbox
                Button(action: onToggleCheck) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14))
                        .foregroundStyle(isChecked ? AppTheme.accentOrange : AppTheme.borderMedium)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(category.color)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text("\(group.fileCount) files")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.textTertiary)
                        }

                        Spacer()

                        Text(group.totalSize.formattedFileSize)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.accentOrange)
                    }
                }
                .buttonStyle(.plain)

                // Delete folder button
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.accentRed)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.trailing, 4)
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if isExpanded {
                let sorted = group.files.sorted(by: { $0.size > $1.size })
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
        .alert("Delete Folder", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(group.name)", role: .destructive) {
                onDeleteFolder(group.path)
            }
        } message: {
            Text("Move \"\(group.name)\" (\(group.totalSize.formattedFileSize)) to Trash?")
        }
    }
}
