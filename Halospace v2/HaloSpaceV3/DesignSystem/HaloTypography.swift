//
//  HaloTypography.swift
//  HaloSpace V3
//

import SwiftUI

enum HaloFont {
    static let display = Font.system(size: 42, weight: .semibold, design: .default)
    static let wordmark = Font.system(size: 38, weight: .semibold, design: .default)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 27, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let callout = Font.system(size: 15, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 14, weight: .medium, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let micro = Font.system(size: 10, weight: .semibold, design: .default)
    static let mono = Font.system(size: 12, weight: .medium, design: .monospaced)
    static let monoLarge = Font.system(size: 30, weight: .light, design: .monospaced)
}

enum HaloSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 34
    static let xxl: CGFloat = 52
}

enum HaloRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 30
    static let window: CGFloat = 22
    static let pill: CGFloat = 999
}

enum HaloTracking {
    static let wide: CGFloat = 2.4
    static let tighter: CGFloat = -0.6
}
