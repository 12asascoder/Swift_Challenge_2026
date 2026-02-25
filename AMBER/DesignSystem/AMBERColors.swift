import SwiftUI

// MARK: - Palette
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    // Primary palette
    static let amberBG          = Color(hex: "0D0D0A")
    static let amberCard        = Color(hex: "1A1A12")
    static let amberCardBorder  = Color(hex: "2E2D1A")
    static let amberAccent      = Color(hex: "F5A623")
    static let amberAccentDim   = Color(hex: "C47D0E")
    static let amberButtonOlive = Color(hex: "3A3520")
    static let amberSubtext     = Color(hex: "8A8A6A")
    static let amberIconBG      = Color(hex: "2A2810")
}

// MARK: - Typography helpers
struct AMBERFont {
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
