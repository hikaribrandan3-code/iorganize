import SwiftUI

/// Light neutral base with yellow accent — Apple Settings inspired.
enum Theme {
    // Canvas layers
    static let windowBackground = Color(hex: 0xF5F5F7)
    static let sidebarBackground = Color(hex: 0xEBEBF0)
    static let card = Color(hex: 0xFFFFFF)
    static let cardElevated = Color(hex: 0xF9F9FB)
    static let heroTop = Color(hex: 0xFFFFFF)
    static let heroBottom = Color(hex: 0xF5F5F7)

    // Accent (Yellow) — more saturated for better visibility
    static let gold = Color(hex: 0xF59E0B)
    static let goldSoft = Color(hex: 0xFCD34D)
    static let goldDim = Color(hex: 0xB45309)

    // Text
    static let textPrimary = Color(hex: 0x1F2937)
    static let textSecondary = Color(hex: 0x6B7280)
    static let textTertiary = Color(hex: 0x9CA3AF)

    // Semantic
    static let success = Color(hex: 0x10B981)
    static let danger = Color(hex: 0xEF4444)

    static let cardStroke = Color.black.opacity(0.08)
    static let cornerRadius: CGFloat = 12
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Shared modifiers

struct CardBackground: ViewModifier {
    var elevated = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(elevated ? Theme.cardElevated : Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .strokeBorder(Theme.cardStroke, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func card(elevated: Bool = false) -> some View {
        modifier(CardBackground(elevated: elevated))
    }
}

struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(Theme.textPrimary)
    }
}
