import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var isSearchFocused: Bool
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("MacUninstaller")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textTertiary)
                    TextField("Search apps...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textPrimary)
                        .focused($isSearchFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(width: 220)
                .background(AppTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.borderMedium, lineWidth: 1)
                )

                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.backgroundSecondary)

            Divider().background(AppTheme.borderLight)

            StorageInsightsRow(insights: viewModel.insights)

            Divider().background(AppTheme.backgroundCard)

            FilterTabsView(
                activeFilter: $viewModel.activeFilter,
                sortOption: $viewModel.sortOption
            )

            Divider().background(AppTheme.backgroundCard)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Scanning apps...")
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            } else {
                AppListView(viewModel: viewModel)
            }
        }
        .overlay {
            if viewModel.isUninstalling {
                UninstallProgressView(
                    message: viewModel.uninstallProgress,
                    appNames: viewModel.uninstallAppNames,
                    totalApps: viewModel.uninstallTotalCount,
                    currentIndex: viewModel.uninstallCurrentIndex
                )
                .transition(.opacity)
            }
        }
        .background(AppTheme.backgroundPrimary)
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.characters == "f" {
                    isSearchFocused = true
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .task {
            await viewModel.loadApps()
        }
        .sheet(item: $viewModel.appToUninstall) { app in
            UninstallSheetView(
                app: app,
                onDismiss: { viewModel.appToUninstall = nil },
                onComplete: {
                    Task { await viewModel.loadApps() }
                }
            )
        }
        .alert("Batch Uninstall", isPresented: $viewModel.showBatchConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall \(viewModel.selectedAppsCount) Apps", role: .destructive) {
                Task { await viewModel.executeBatchUninstall() }
            }
        } message: {
            let names = viewModel.selectedApps.prefix(5).map(\.name).joined(separator: ", ")
            let extra = viewModel.selectedAppsCount > 5 ? " and \(viewModel.selectedAppsCount - 5) more" : ""
            Text("Remove \(names)\(extra)? This will move the apps and their associated files to Trash.")
        }
        .onChange(of: appState.pendingUninstallPath) { newPath in
            guard let path = newPath else { return }
            if let app = viewModel.allApps.first(where: { $0.bundlePath.path == path }) {
                viewModel.prepareUninstall(app: app)
            }
            appState.pendingUninstallPath = nil
        }
    }
}
