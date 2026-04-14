import SwiftUI

struct FilterTabsView: View {
    @Binding var activeFilter: AppFilter
    @Binding var sortOption: SortOption

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppFilter.allCases, id: \.self) { filter in
                Button(action: { activeFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: activeFilter == filter ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            activeFilter == filter
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(AppTheme.backgroundCard)
                        )
                        .foregroundStyle(activeFilter == filter ? .white : AppTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("Sort by:")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                Picker("", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
