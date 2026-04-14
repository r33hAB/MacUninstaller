import SwiftUI

struct StorageOverviewView: View {
    @StateObject private var viewModel = StorageViewModel()
    @State private var showCategoryPicker = false
    @State private var showSuggestions = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                // Animated scanning view
                Spacer()
                VStack(spacing: 20) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primaryGradient, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(scanRotation))

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppTheme.primaryGradient)
                    }

                    // Category name
                    Text(viewModel.scanCurrentCategory)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    // Status
                    Text(viewModel.scanProgress)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)

                    // File count
                    Text("\(viewModel.scanFileCount.formatted()) files found")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.accentOrange)

                    // Progress bar
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.backgroundCard)
                                .frame(height: 8)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.primaryGradient)
                                    .frame(width: geo.size.width * scanProgress, height: 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.clear, .white.opacity(0.3), .clear],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 40)
                                            .offset(x: shimmerOffset)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .animation(.easeInOut(duration: 0.3), value: scanProgress)
                            }
                            .frame(height: 8)
                        }
                        .frame(width: 280)

                        HStack {
                            Text("\(viewModel.scanCategoryIndex) of \(viewModel.scanCategoryTotal)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.accentOrange)
                            Spacer()
                            Text("\(Int(scanProgress * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(width: 280)
                    }
                }
                Spacer()
            } else if viewModel.categoryResults.isEmpty {
                // Initial scan view with category picker
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("Analyze your storage")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Scan your files to find cleanup opportunities")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)

                    // Category toggles
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SCAN THESE FOLDERS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(AppTheme.textTertiary)

                        let toggleableCategories = StorageCategory.allCases.filter {
                            $0 != .applications && $0 != .system
                        }

                        ForEach(toggleableCategories, id: \.self) { category in
                            Button(action: { viewModel.toggleCategory(category) }) {
                                HStack(spacing: 10) {
                                    Image(systemName: viewModel.enabledCategories.contains(category)
                                          ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 14))
                                        .foregroundStyle(viewModel.enabledCategories.contains(category)
                                                        ? AppTheme.accentOrange : AppTheme.borderMedium)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(category.color)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Image(systemName: category.icon)
                                                .font(.system(size: 8))
                                                .foregroundStyle(.white)
                                        )

                                    Text(category.rawValue)
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Spacer()

                                    Text(category.directories.first?.lastPathComponent ?? "")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .frame(width: 320)
                    .background(AppTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.borderLight, lineWidth: 1)
                    )

                    Button("Scan Now") {
                        Task { await viewModel.scan() }
                    }
                    .buttonStyle(GradientButtonStyle())
                    .disabled(viewModel.enabledCategories.isEmpty)
                }
                Spacer()
            } else {
                // Results view
                ScrollView {
                    VStack(spacing: 0) {
                        DiskUsageBarView(
                            diskInfo: viewModel.diskInfo,
                            categories: viewModel.sortedCategories
                        )

                        Divider().background(AppTheme.backgroundCard)

                        // Quick Clean button
                        if !viewModel.activeSuggestions.isEmpty {
                            let totalReclaimable = viewModel.activeSuggestions.reduce(Int64(0)) { $0 + $1.totalSize }
                            let suggestionCount = viewModel.activeSuggestions.count

                            Button(action: { showSuggestions = true }) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14))
                                                .foregroundStyle(AppTheme.accentOrange)
                                            Text("Smart Cleanup")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(AppTheme.textPrimary)
                                        }
                                        Text("\(suggestionCount) suggestions found · \(totalReclaimable.formattedFileSize) reclaimable")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text("Review")
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.primaryGradient)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .padding(16)
                                .background(AppTheme.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.accentOrange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                            Divider().background(AppTheme.backgroundCard).padding(.top, 8)
                        }

                        VStack(spacing: 6) {
                            HStack {
                                Text("CATEGORIES")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1)
                                    .foregroundStyle(AppTheme.textTertiary)
                                Spacer()
                                Button("Rescan") {
                                    Task { await viewModel.scan() }
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.accentOrange)
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                            ForEach(viewModel.sortedCategories, id: \.0) { category, size in
                                StorageCategoryRowView(
                                    category: category,
                                    size: size,
                                    fileCount: viewModel.categoryFileCount(category),
                                    badge: badgeFor(category),
                                    onTap: { viewModel.selectedCategory = category }
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .sheet(item: $viewModel.selectedCategory) { category in
                    CategoryDetailView(
                        category: category,
                        viewModel: viewModel
                    )
                }
                .sheet(isPresented: $showSuggestions) {
                    SuggestionsDetailView(viewModel: viewModel)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Animation State

    @State private var scanRotation: Double = 0
    @State private var shimmerOffset: CGFloat = -50

    private var scanProgress: CGFloat {
        guard viewModel.scanCategoryTotal > 0 else { return 0 }
        return CGFloat(viewModel.scanCategoryIndex) / CGFloat(viewModel.scanCategoryTotal)
    }

    // MARK: - Helpers

    private func badgeFor(_ category: StorageCategory) -> String? {
        switch category {
        case .downloads:
            let staleCount = viewModel.filesForCategory(.downloads).filter(\.isStale).count
            return staleCount > 0 ? "CLEANUP AVAILABLE" : nil
        case .caches:
            let size = viewModel.categorySize(.caches)
            return size > 500_000_000 ? "\(size.formattedFileSize) RECLAIMABLE" : nil
        case .developer:
            let size = viewModel.categorySize(.developer)
            return size > 0 ? "\(size.formattedFileSize) RECLAIMABLE" : nil
        default:
            return nil
        }
    }
}
