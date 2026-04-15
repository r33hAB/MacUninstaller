import SwiftUI

struct DiskUsageBarView: View {
    let diskInfo: DiskInfo
    let categories: [(StorageCategory, Int64)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Macintosh HD")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(diskInfo.usedSpace.formattedFileSize) used of \(diskInfo.totalSpace.formattedFileSize)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(diskInfo.freeSpace.formattedFileSize)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("available")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(categories, id: \.0) { category, size in
                        let ratio = diskInfo.totalSpace > 0
                            ? CGFloat(size) / CGFloat(diskInfo.totalSpace) : 0
                        if ratio > 0.005 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(category.color)
                                .frame(width: max(geo.size.width * ratio, 4))
                        }
                    }
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.backgroundCard)
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack(spacing: 12) {
                ForEach(categories.prefix(7), id: \.0) { category, _ in
                    HStack(spacing: 4) {
                        Circle().fill(category.color).frame(width: 8, height: 8)
                        Text(category.rawValue)
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
        .padding(24)
    }
}
