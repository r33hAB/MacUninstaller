import SwiftUI

enum AppSection: String, CaseIterable {
    case apps = "Apps"
    case storage = "Storage"
}

struct SidebarView: View {
    @Binding var selectedSection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(AppSection.allCases, id: \.self) { section in
                Button(action: { selectedSection = section }) {
                    HStack(spacing: 8) {
                        Image(systemName: section == .apps ? "square.stack.3d.up.fill" : "chart.bar.fill")
                            .font(.system(size: 13))
                            .frame(width: 20)
                        Text(section.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(selectedSection == section ? .white : AppTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        selectedSection == section
                            ? AnyShapeStyle(AppTheme.primaryGradient)
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 160)
        .background(AppTheme.backgroundSecondary)
    }
}
