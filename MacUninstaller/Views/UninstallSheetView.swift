import SwiftUI

struct UninstallSheetView: View {
    let app: AppInfo
    let onDismiss: () -> Void
    var onComplete: (() -> Void)?
    @StateObject private var viewModel: UninstallSheetViewModel
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isUninstalling = false
    @State private var uninstallDone = false

    init(app: AppInfo, onDismiss: @escaping () -> Void, onComplete: (() -> Void)? = nil) {
        self.app = app
        self.onDismiss = onDismiss
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: UninstallSheetViewModel(app: app))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("Uninstall \(app.name)?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(app.bundleIdentifier)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)

                if app.source == .system {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.accentRed)
                        Text("This is a macOS system app. Removing it may break OS functionality. This cannot be undone with Trash — a full reinstall may be required.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.accentRed)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider().background(AppTheme.backgroundCard)

            // Size summary
            HStack(spacing: 0) {
                sizeStat(title: "App Bundle", value: app.bundleSize.formattedFileSize)
                dividerLine
                sizeStat(title: "Associated Files", value: viewModel.associatedFilesSelectedSize.formattedFileSize)
                dividerLine
                sizeStat(title: "Total to Remove", value: viewModel.totalSelectedSize.formattedFileSize, color: AppTheme.accentOrange)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)

            Divider().background(AppTheme.backgroundCard)

            // File list header
            HStack {
                Text("FILES TO REMOVE")
                    .font(.system(size: 11))
                    .tracking(1)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Button(action: { viewModel.selectAll() }) {
                    Text("Select All")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.accentOrange)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // File list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // App bundle entry
                    VStack(alignment: .leading, spacing: 6) {
                        Text("APP BUNDLE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(AppTheme.accentBlue)

                        HStack(spacing: 10) {
                            Button(action: { viewModel.includeAppBundle.toggle() }) {
                                Image(systemName: viewModel.includeAppBundle ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .foregroundStyle(viewModel.includeAppBundle ? AppTheme.accentOrange : AppTheme.borderMedium)
                            }
                            .buttonStyle(.plain)

                            Text(app.bundlePath.path)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)

                            Spacer()

                            Text(app.bundleSize.formattedFileSize)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .padding(8)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Associated files by category
                    ForEach(Array(viewModel.filesByCategory.enumerated()), id: \.element.category) { groupIndex, group in
                        let offset = viewModel.filesByCategory.prefix(groupIndex).reduce(0) { $0 + $1.files.count }
                        FileGroupView(
                            category: group.category,
                            files: group.files,
                            onToggle: { viewModel.toggleFile(at: $0) },
                            globalOffset: offset
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 240)

            Divider().background(AppTheme.backgroundCard)

            // Actions
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.borderLight, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    isUninstalling = true
                    let paths = viewModel.selectedPaths
                    Task {
                        let service = UninstallService()
                        do {
                            let result = try await service.uninstall(paths: paths)
                            if !result.failedPaths.isEmpty {
                                let failures = result.failedPaths.map { "\($0.path.lastPathComponent): \($0.error.localizedDescription)" }
                                errorMessage = failures.joined(separator: "\n")
                                showError = true
                                isUninstalling = false
                                return
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                            isUninstalling = false
                            return
                        }
                        uninstallDone = true
                        try? await Task.sleep(for: .seconds(1))
                        onDismiss()
                        onComplete?()
                    }
                }) {
                    Text("Move to Trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(isUninstalling)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Text("Files will be moved to Trash. You can restore them until Trash is emptied.")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.bottom, 16)
        }
        .frame(width: 480)
        .background(AppTheme.backgroundSecondary)
        .overlay {
            if isUninstalling {
                UninstallProgressView(
                    message: uninstallDone ? "Done!" : "Removing \(app.name)...",
                    appNames: [app.name],
                    totalApps: 1,
                    currentIndex: uninstallDone ? 1 : 0
                )
                .transition(.opacity)
            }
        }
        .alert("Uninstall Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func sizeStat(title: String, value: String, color: Color = AppTheme.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10))
                .tracking(1)
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(AppTheme.borderLight)
            .frame(width: 1, height: 30)
    }
}
