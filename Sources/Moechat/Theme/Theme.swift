import SwiftUI

/// moechat 的统一视觉语言。
/// 五个原生宿主（macOS / Windows / Linux / iOS / Android）各自实现，但共用这一套取值。
enum Theme {
    static let background = Color(hex: 0x0A0B0D)

    static let surface = Color.white.opacity(0.055)
    static let surfaceStroke = Color.white.opacity(0.10)
    static let raised = Color.white.opacity(0.07)

    static let primaryText = Color.white.opacity(0.92)
    static let secondaryText = Color.white.opacity(0.66)
    static let tertiaryText = Color.white.opacity(0.42)
    static let faintText = Color.white.opacity(0.28)

    static let addressBar = Color.white.opacity(0.06)
    static let addressText = Color.white.opacity(0.80)

    static let radiusContainer: CGFloat = 26
    static let radiusGridCell: CGFloat = 18

    static let shellPadding: CGFloat = 14
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
