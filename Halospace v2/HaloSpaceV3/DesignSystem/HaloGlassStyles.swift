//
//  HaloGlassStyles.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloGlassSurface<S: InsettableShape>: View {
    let shape: S
    var tint: Color = HaloColor.glassTint
    var strokeOpacity: Double = 0.14
    var strokeWidth: CGFloat = 1
    var shadowRadius: CGFloat = 22

    var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(tint))
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(strokeOpacity),
                            Color.white.opacity(strokeOpacity * 0.24),
                            Color.white.opacity(strokeOpacity * 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth
                )
            )
            .shadow(color: Color.black.opacity(0.36), radius: shadowRadius, x: 0, y: shadowRadius * 0.42)
    }
}

private struct HaloGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let strokeOpacity: Double
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint,
                strokeOpacity: strokeOpacity,
                shadowRadius: shadowRadius
            )
        )
    }
}

extension View {
    func haloGlass(
        cornerRadius: CGFloat = HaloRadius.lg,
        tint: Color = HaloColor.glassTint,
        strokeOpacity: Double = 0.14,
        shadowRadius: CGFloat = 22
    ) -> some View {
        modifier(
            HaloGlassModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                strokeOpacity: strokeOpacity,
                shadowRadius: shadowRadius
            )
        )
    }

    func haloWindowChrome(cornerRadius: CGFloat = HaloRadius.window, focused: Bool = false) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(HaloColor.windowGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: focused
                                    ? [HaloColor.ice.opacity(0.55), Color.white.opacity(0.14), HaloColor.ice.opacity(0.22)]
                                    : [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: focused ? 1.2 : 0.8
                        )
                )
                .shadow(color: Color.black.opacity(focused ? 0.55 : 0.38), radius: focused ? 30 : 20, x: 0, y: 16)
                .shadow(color: focused ? HaloColor.ice.opacity(0.10) : .clear, radius: 26, x: 0, y: 0)
        )
    }
}

struct HaloHairline: View {
    var opacity: Double = 0.08

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(opacity), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}
