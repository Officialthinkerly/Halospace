//
//  HaloLogo.swift
//  HaloSpace V3
//
//  A procedural, replaceable HaloSpace monogram: a luminous core wrapped by
//  a quiet orbital halo. Drop a "HaloLogo" image into Assets.xcassets to
//  replace it with the production mark without touching call sites.
//

import SwiftUI

struct HaloLogoMark: View {
    var size: CGFloat = 120
    var animated: Bool = true
    var glowIntensity: Double = 0.75

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbit = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            // Ambient bloom behind the mark.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [HaloColor.ice.opacity(0.24), HaloColor.iceDeep.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.82
                    )
                )
                .frame(width: size * 1.7, height: size * 1.7)
                .blur(radius: size * 0.10)
                .opacity(glowIntensity)

            // Halo ring.
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            HaloColor.frost.opacity(0.02),
                            HaloColor.frost.opacity(0.85),
                            HaloColor.ice.opacity(0.95),
                            HaloColor.iceDeep.opacity(0.35),
                            HaloColor.frost.opacity(0.06)
                        ]),
                        center: .center,
                        angle: .degrees(orbit ? 360 : 0)
                    ),
                    lineWidth: max(1.2, size * 0.018)
                )
                .frame(width: size * 0.80, height: size * 0.80)
                .rotationEffect(.degrees(-22))
                .shadow(color: HaloColor.ice.opacity(glowIntensity * 0.35), radius: size * 0.07)

            // Outer orbit.
            Ellipse()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.02), .white.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.8, size * 0.008)
                )
                .frame(width: size * 1.24, height: size * 0.52)
                .rotationEffect(.degrees(orbit ? 360 + 14 : 14))

            // Orbiting satellite.
            Circle()
                .fill(HaloColor.frost)
                .frame(width: max(2.4, size * 0.032), height: max(2.4, size * 0.032))
                .shadow(color: HaloColor.ice, radius: size * 0.035)
                .offset(x: size * 0.62)
                .rotationEffect(.degrees(orbit ? 360 + 14 : 14))

            // Luminous core.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            HaloColor.frost,
                            HaloColor.iceDeep.opacity(0.62),
                            Color(red: 0.055, green: 0.086, blue: 0.14)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 0,
                        endRadius: size * 0.30
                    )
                )
                .frame(width: size * 0.50, height: size * 0.50)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.75)
                )
                .shadow(color: HaloColor.ice.opacity(glowIntensity * 0.55), radius: size * 0.10)
                .scaleEffect(breathe ? 1.025 : 0.995)

            // Specular arc.
            Circle()
                .trim(from: 0.55, to: 0.78)
                .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: max(0.7, size * 0.007), lineCap: .round))
                .frame(width: size * 0.40, height: size * 0.40)
                .rotationEffect(.degrees(orbit ? 360 : 0))
                .blur(radius: 0.25)
        }
        .frame(width: size * 1.35, height: size * 1.35)
        .accessibilityHidden(true)
        .onAppear {
            guard animated, !reduceMotion else { return }
            withAnimation(HaloMotion.orbit) { orbit = true }
            withAnimation(Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

struct HaloWordmark: View {
    var size: CGFloat = 38
    var showsDot: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("HaloSpace")
                .font(.system(size: size, weight: .semibold, design: .default))
                .tracking(size * HaloTracking.tighter * 0.30)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, HaloColor.frost.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if showsDot {
                Circle()
                    .fill(HaloColor.ice)
                    .frame(width: size * 0.11, height: size * 0.11)
                    .offset(y: -size * 0.55)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct HaloBrandLockup: View {
    var markSize: CGFloat = 104
    var wordmarkSize: CGFloat = 38
    var spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: spacing) {
            HaloLogoMark(size: markSize)
            HaloWordmark(size: wordmarkSize)
        }
    }
}
