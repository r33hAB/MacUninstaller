import SwiftUI

struct StorageInsightsRow: View {
    let insights: StorageInsights

    var body: some View {
        VStack(spacing: 12) {
            // Disk usage bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DISK STORAGE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.textTertiary)
                    Spacer()
                    Text("\(insights.diskInfo.usedSpace.formattedFileSize) used of \(insights.diskInfo.totalSpace.formattedFileSize)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("·")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("\(insights.diskInfo.freeSpace.formattedFileSize) free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.accentOrange)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.backgroundCard)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(usageColor)
                            .frame(width: geometry.size.width * usageRatio, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Insight cards
            HStack(spacing: 16) {
                insightCard(
                    title: "Reclaimable Space",
                    value: insights.totalReclaimableSpace.formattedFileSize,
                    subtitle: "across \(insights.totalApps) apps",
                    valueColor: AppTheme.accentOrange
                )
                insightCard(
                    title: "Installed Apps",
                    value: "\(insights.totalApps)",
                    subtitle: "\(insights.appStoreApps) from App Store",
                    valueColor: AppTheme.textPrimary
                )
                insightCard(
                    title: "Unused (90+ days)",
                    value: "\(insights.unusedApps.count)",
                    subtitle: "using \(insights.unusedTotalSize.formattedFileSize)",
                    valueColor: AppTheme.accentRed
                )
                insightCard(
                    title: "Largest App",
                    value: insights.largestApp?.name ?? "—",
                    subtitle: insights.largestApp?.totalSize.formattedFileSize ?? "",
                    valueColor: AppTheme.textPrimary
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private var usageRatio: CGFloat {
        guard insights.diskInfo.totalSpace > 0 else { return 0 }
        return min(CGFloat(insights.diskInfo.usedSpace) / CGFloat(insights.diskInfo.totalSpace), 1.0)
    }

    private var usageColor: some ShapeStyle {
        if insights.diskInfo.usedPercentage > 90 {
            return AnyShapeStyle(AppTheme.accentRed)
        } else if insights.diskInfo.usedPercentage > 70 {
            return AnyShapeStyle(AppTheme.accentOrange)
        } else {
            return AnyShapeStyle(AppTheme.primaryGradient)
        }
    }

    private func insightCard(title: String, value: String, subtitle: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11))
                .tracking(1)
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(valueColor)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}
