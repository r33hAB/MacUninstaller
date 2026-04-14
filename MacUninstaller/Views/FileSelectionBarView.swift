import SwiftUI

struct FileSelectionBarView: View {
    let selectedCount: Int
    let totalSize: Int64
    let onCleanup: () -> Void
    let isCleaningUp: Bool

    var body: some View {
        HStack {
            Text("\(selectedCount) files selected \u{00B7} \(totalSize.formattedFileSize)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Button(action: onCleanup) {
                HStack(spacing: 6) {
                    if isCleaningUp {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(isCleaningUp ? "Cleaning..." : "Move to Trash")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(isCleaningUp || selectedCount == 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.backgroundSecondary)
        .overlay(
            Rectangle().fill(AppTheme.borderLight).frame(height: 1),
            alignment: .top
        )
    }
}
