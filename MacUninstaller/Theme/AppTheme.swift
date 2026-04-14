import SwiftUI

enum AppTheme {
    static let backgroundPrimary = Color(hex: 0x0A0A0A)
    static let backgroundSecondary = Color(hex: 0x111111)
    static let backgroundCard = Color(hex: 0x1A1A1A)

    static let borderLight = Color(hex: 0x222222)
    static let borderMedium = Color(hex: 0x333333)

    static let textPrimary = Color(hex: 0xEEEEEE)
    static let textSecondary = Color(hex: 0x888888)
    static let textTertiary = Color(hex: 0x555555)

    static let accentOrange = Color(hex: 0xF97316)
    static let accentRed = Color(hex: 0xEF4444)
    static let accentBlue = Color(hex: 0x667EEA)

    static let primaryGradient = LinearGradient(
        colors: [accentOrange, accentRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dangerBackground = Color(hex: 0x2A1A1A)
    static let dangerBorder = Color(hex: 0xEF4444).opacity(0.3)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
