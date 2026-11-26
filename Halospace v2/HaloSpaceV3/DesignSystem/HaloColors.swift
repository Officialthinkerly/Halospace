//
//  HaloColors.swift
//  HaloSpace V3
//
//  The restrained, monochrome palette that anchors the HaloSpace identity.
//

import SwiftUI

enum HaloColor {
    static let void = Color(red: 0.016, green: 0.022, blue: 0.031)
    static let space = Color(red: 0.031, green: 0.043, blue: 0.059)
    static let surface = Color(red: 0.047, green: 0.063, blue: 0.082)
    static let elevated = Color(red: 0.075, green: 0.094, blue: 0.118)

    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.58)
    static let textTertiary = Color.white.opacity(0.34)

    static let hairline = Color.white.opacity(0.09)
    static let hairlineStrong = Color.white.opacity(0.16)

    static let ice = Color(red: 0.718, green: 0.843, blue: 1.0)
    static let iceDeep = Color(red: 0.373, green: 0.592, blue: 0.965)
    static let frost = Color(red: 0.886, green: 0.925, blue: 0.973)

    static let violet = Color(red: 0.635, green: 0.635, blue: 0.980)
    static let success = Color(red: 0.467, green: 0.902, blue: 0.706)
    static let warning = Color(red: 0.965, green: 0.780, blue: 0.427)
    static let danger = Color(red: 0.965, green: 0.435, blue: 0.463)

    static let glassTint = Color.white.opacity(0.045)
    static let glassTintStrong = Color.white.opacity(0.075)

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [frost, ice, iceDeep.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var windowGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.082, green: 0.102, blue: 0.129).opacity(0.96),
                Color(red: 0.035, green: 0.047, blue: 0.063).opacity(0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func accent(_ accent: HaloAccent) -> Color {
        switch accent {
        case .ice: return ice
        case .violet: return violet
        case .mint: return success
        case .amber: return warning
        case .silver: return frost
        }
    }
}

enum HaloAccent: String, Codable, CaseIterable {
    case ice
    case violet
    case mint
    case amber
    case silver
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
