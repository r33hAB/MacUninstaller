import SwiftUI

struct UninstallProgressView: View {
    let message: String
    let appNames: [String]
    let totalApps: Int
    let currentIndex: Int

    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var particleOpacity: Double = 0

    private var progress: Double {
        guard totalApps > 0 else { return 0 }
        return Double(currentIndex) / Double(totalApps)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Animated icon area
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(AppTheme.primaryGradient, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)

                    // Icon background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.accentOrange.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)

                    // Trash icon
                    Image(systemName: "trash.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(AppTheme.primaryGradient)
                        .rotationEffect(.degrees(iconRotation))
                }
                .padding(.bottom, 24)

                // Current app name
                if currentIndex < appNames.count {
                    Text(appNames[currentIndex])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.bottom, 4)
                }

                // Status text
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)

                // Progress bar
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.backgroundCard)
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppTheme.borderLight, lineWidth: 1)
                            )

                        // Fill
                        GeometryReader { geo in
                            let width = max(geo.size.width * progress, 0)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.primaryGradient)
                                .frame(width: width, height: 12)
                                .overlay(
                                    // Shimmer effect
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.3), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 60)
                                        .offset(x: shimmerOffset)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .animation(.easeInOut(duration: 0.4), value: progress)
                        }
                        .frame(height: 12)
                    }

                    // Counter
                    HStack {
                        Text("\(currentIndex) of \(totalApps)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.accentOrange)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(width: 280)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.borderMedium, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.accentOrange.opacity(0.1), radius: 30)
            )
        }
        .onAppear {
            // Shimmer animation
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 300
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            // Subtle icon wobble
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                iconRotation = -5
            }
        }
    }
}

/// Simpler version for single-app uninstall in the sheet
struct UninstallSheetProgressView: View {
    let appName: String
    @State private var shimmerOffset: CGFloat = -100
    @State private var dotCount: Int = 0

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            // Animated bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.backgroundCard)
                    .frame(height: 6)

                // Indeterminate animated fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 80, height: 6)
                    .offset(x: shimmerOffset)
            }
            .frame(width: 200, height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text("Removing \(appName)\(String(repeating: ".", count: dotCount))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                shimmerOffset = 120
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}
