import SwiftUI

struct CategoryDetailView: View {
    let category: StorageCategory
    @ObservedObject var viewModel: StorageViewModel
    @Environment(\.dismiss) private var dismiss

    var files: [ScannedFile] { viewModel.filesForCategory(category) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                }
                .buttonStyle(.plain)

                Text(category.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\u{00B7} \(files.count.formatted()) files \u{00B7} \(viewModel.categorySize(category).formattedFileSize)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)

                Spacer()

                Picker("", selection: $viewModel.detailViewMode) {
                    ForEach(DetailViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider().background(AppTheme.borderLight)

            // Content
            ScrollView {
                VStack(spacing: 6) {
                    switch viewModel.detailViewMode {
                    case .byFolder:
                        ForEach(viewModel.groupFilesByFolder(files, category: category)) { group in
                            FolderGroupView2(
                                group: group,
                                category: category,
                                onToggleFile: { viewModel.toggleFileSelection($0, in: category) },
                                onDeleteFolder: { url in
                                    Task { await viewModel.deleteFolder(at: url) }
                                },
                                isChecked: viewModel.selectedFolders.contains(group.path),
                                onToggleCheck: { viewModel.toggleFolderSelection(group.path) }
                            )
                        }
                    case .byType:
                        ForEach(viewModel.groupFilesByType(files)) { group in
                            FileTypeGroupView2(
                                group: group,
                                category: category,
                                onToggleFile: { viewModel.toggleFileSelection($0, in: category) }
                            )
                        }
                    case .byDate:
                        ForEach(viewModel.groupFilesByDate(files)) { group in
                            DateGroupView(
                                group: group,
                                category: category,
                                onToggleFile: { viewModel.toggleFileSelection($0, in: category) }
                            )
                        }
                    }
                }
                .padding(24)
            }

            // Selection bar — show for file or folder selections
            if !viewModel.selectedFiles.isEmpty || !viewModel.selectedFolders.isEmpty {
                let totalCount = viewModel.selectedFiles.count + viewModel.selectedFolders.count
                let totalSize = viewModel.selectedFilesTotalSize + viewModel.selectedFoldersTotalSize
                FileSelectionBarView(
                    selectedCount: totalCount,
                    totalSize: totalSize,
                    onCleanup: {
                        Task {
                            if !viewModel.selectedFolders.isEmpty {
                                await viewModel.deleteSelectedFolders()
                            }
                            if !viewModel.selectedFiles.isEmpty {
                                await viewModel.cleanupSelected()
                            }
                        }
                    },
                    isCleaningUp: viewModel.isCleaningUp
                )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(AppTheme.backgroundPrimary)
        .overlay {
            if viewModel.isCleaningUp {
                UninstallProgressView(
                    message: viewModel.cleanupMessage,
                    appNames: [viewModel.cleanupMessage],
                    totalApps: 1,
                    currentIndex: viewModel.cleanupMessage == "Done!" ? 1 : 0
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.detailViewMode = .byFolder
        }
    }
}
