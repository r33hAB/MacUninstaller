import SwiftUI

struct DateGroupView: View {
    let group: DateGroupResult
    let category: StorageCategory
    let onToggleFile: (UUID) -> Void
    @State private var isExpanded = false

    private let maxVisible = 30

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(group.bracket.color)
                        .frame(width: 4, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(group.bracket.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            if group.bracket.isStale {
                                Text("STALE")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(AppTheme.accentRed)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        Text("\(group.fileCount) files")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Spacer()

                    Text(group.totalSize.formattedFileSize)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(group.bracket.color)

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
                VStack(spacing: 3) {
                    ForEach(sorted.prefix(maxVisible)) { file in
                        ScannedFileRowView(
                            file: file,
                            onToggle: { onToggleFile(file.id) }
                        )
                    }
                    if group.fileCount > maxVisible {
                        Text("+ \(group.fileCount - maxVisible) smaller files (\(remainingSize(sorted).formattedFileSize))")
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

    private func remainingSize(_ sorted: [ScannedFile]) -> Int64 {
        sorted.dropFirst(maxVisible).reduce(0) { $0 + $1.size }
    }
}
