//
//  HaloAnimations.swift
//  HaloSpace V3
//

import SwiftUI

enum HaloMotion {
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.88)
    static let snappy = Animation.spring(response: 0.34, dampingFraction: 0.82)
    static let quick = Animation.easeOut(duration: 0.18)
    static let fade = Animation.easeInOut(duration: 0.28)
    static let halo = Animation.easeInOut(duration: 7.5).repeatForever(autoreverses: true)
    static let orbit = Animation.linear(duration: 26).repeatForever(autoreverses: false)

    static func reduced(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

struct HaloPressStyle: ButtonStyle {
    var scale: CGFloat = 0.975
    var reduceMotion: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(reduceMotion ? nil : HaloMotion.quick, value: configuration.isPressed)
    }
}

struct HaloRevealModifier: ViewModifier {
    let index: Int
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(
                reduceMotion ? nil : HaloMotion.gentle.delay(Double(index) * 0.055),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

extension View {
    func haloReveal(_ index: Int) -> some View {
        modifier(HaloRevealModifier(index: index))
    }
}
