import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    if viewModel.selectedAppIDs.count == viewModel.filteredApps.count {
                        viewModel.deselectAll()
                    } else {
                        viewModel.selectAll()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.selectedAppIDs.count == viewModel.filteredApps.count
                              ? "checkmark.square.fill" : "square")
                            .foregroundStyle(AppTheme.borderMedium)
                        Text("Select all")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if viewModel.selectedAppsCount > 0 {
                    Button(action: { viewModel.showBatchConfirm = true }) {
                        Text("Batch Uninstall (\(viewModel.selectedAppsCount) selected)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(GradientButtonStyle())
                } else {
                    Text("Batch Uninstall (0 selected)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.filteredApps) { app in
                        AppRowView(
                            app: app,
                            isSelected: viewModel.selectedAppIDs.contains(app.id),
                            onToggleSelect: { viewModel.toggleSelection(for: app) },
                            onUninstall: { viewModel.prepareUninstall(app: app) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
