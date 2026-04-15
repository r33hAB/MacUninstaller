import SwiftUI

struct SuggestionsDetailView: View {
    @ObservedObject var viewModel: StorageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var deletingFiles: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Smart Cleanup")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let totalReclaimable = viewModel.activeSuggestions.reduce(Int64(0)) { $0 + $1.totalSize }
                Text("\(totalReclaimable.formattedFileSize) reclaimable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.accentOrange)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider().background(AppTheme.borderLight)

            // Suggestions list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.activeSuggestions) { suggestion in
                        SuggestionRowDetailView(
                            suggestion: suggestion,
                            onDismiss: { viewModel.dismissSuggestion(suggestion) },
                            onDeleteFile: { file in
                                Task { await deleteFile(file) }
                            },
                            onDeleteAll: {
                                Task { await deleteAllIn(suggestion) }
                            },
                            onMoveToApps: { file in
                                Task { await moveToApplications(file) }
                            },
                            onReveal: { file in
                                NSWorkspace.shared.activateFileViewerSelecting([file.path])
                            },
                            deletingFiles: deletingFiles
                        )
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 600, minHeight: 450)
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
    }

    private func deleteFile(_ file: ScannedFile) async {
        viewModel.isCleaningUp = true
        viewModel.cleanupMessage = "Removing \(file.name)..."
        let service = UninstallService()
        do {
            let _ = try await service.uninstall(paths: [file.path])
        } catch {
            print("Delete error: \(error)")
        }
        viewModel.cleanupMessage = "Done!"
        try? await Task.sleep(for: .seconds(1))
        viewModel.isCleaningUp = false
        viewModel.cleanupMessage = ""
    }

    private func deleteAllIn(_ suggestion: CleanupSuggestion) async {
        viewModel.isCleaningUp = true
        viewModel.cleanupMessage = "Removing \(suggestion.fileCount) files..."
        let paths = suggestion.files.map(\.path)
        let service = UninstallService()
        do {
            let _ = try await service.uninstall(paths: paths)
        } catch {
            print("Batch delete error: \(error)")
        }
        viewModel.cleanupMessage = "Done!"
        try? await Task.sleep(for: .seconds(1))
        viewModel.isCleaningUp = false
        viewModel.cleanupMessage = ""
    }

    private func moveToApplications(_ file: ScannedFile) async {
        let dest = URL(filePath: "/Applications/\(file.name)")
        do {
            try FileManager.default.moveItem(at: file.path, to: dest)
        } catch {
            // Try with admin if permission denied
            let service = UninstallService()
            do {
                // Use mv via the auth system
                let _ = try await service.uninstall(paths: []) // just to trigger auth
            } catch {}
            print("Move to Applications error: \(error)")
        }
        await viewModel.scan()
    }
}

struct SuggestionRowDetailView: View {
    let suggestion: CleanupSuggestion
    let onDismiss: () -> Void
    let onDeleteFile: (ScannedFile) -> Void
    let onDeleteAll: () -> Void
    let onMoveToApps: (ScannedFile) -> Void
    let onReveal: (ScannedFile) -> Void
    let deletingFiles: Set<UUID>
    @State private var isExpanded = false
    @State private var showDeleteAllConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: suggestion.type.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(suggestion.type.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.type.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(suggestion.fileCount) files · \(suggestion.type.description)")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Spacer()

                    Text(suggestion.totalSize.formattedFileSize)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accentOrange)

                    // Action button — Move All for apps, Clean All for others
                    if suggestion.type == .appsInDownloads {
                        Button(action: {
                            for file in suggestion.files {
                                onMoveToApps(file)
                            }
                        }) {
                            Text("Move All")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: 0x3B82F6))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { showDeleteAllConfirm = true }) {
                            Text("Clean All")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.primaryGradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(12)
                .background(AppTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // Expanded file list
            if isExpanded {
                VStack(spacing: 3) {
                    ForEach(suggestion.files.sorted(by: { $0.size > $1.size }).prefix(30)) { file in
                        HStack(spacing: 8) {
                            Image(systemName: file.typeGroup.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textTertiary)
                                .frame(width: 14)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(file.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                // Show app name for caches
                                if suggestion.type == .cacheBloat {
                                    Text(friendlyCacheName(file.name))
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                            }

                            Spacer()

                            Text(file.size.formattedFileSize)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.textTertiary)

                            // Action buttons
                            if file.path.pathExtension == "app" {
                                Button(action: { onMoveToApps(file) }) {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.accentBlue)
                                }
                                .buttonStyle(.plain)
                                .help("Move to Applications")
                            }

                            Button(action: { onReveal(file) }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .help("Reveal in Finder")

                            if deletingFiles.contains(file.id) {
                                ProgressView()
                                    .controlSize(.mini)
                                    .frame(width: 16)
                            } else {
                                Button(action: { onDeleteFile(file) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.accentRed)
                                }
                                .buttonStyle(.plain)
                                .help("Move to Trash")
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if suggestion.fileCount > 30 {
                        Text("+ \(suggestion.fileCount - 30) more files")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, 4)
                    }
                }
                .padding(.leading, 36)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
        }
        .alert("Clean All", isPresented: $showDeleteAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(suggestion.fileCount) files", role: .destructive) {
                onDeleteAll()
            }
        } message: {
            Text("Move all \(suggestion.fileCount) files (\(suggestion.totalSize.formattedFileSize)) to Trash?")
        }
    }

    /// Convert bundle ID cache names to friendly app names
    private func friendlyCacheName(_ name: String) -> String {
        // com.apple.Safari -> Safari
        // com.spotify.client -> Spotify
        let parts = name.split(separator: ".")
        if parts.count >= 3 {
            return parts.last.map(String.init)?.capitalized ?? name
        }
        return name
    }
}
