//
//  HaloBackground.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloAmbientBackground: View {
    enum Mood {
        case deepSpace
        case workspace
        case dusk
    }

    var mood: Mood = .deepSpace

    var body: some View {
        ZStack {
            HaloColor.void
            baseGradient
            haloGlow
            HorizonGlow(opacity: mood == .workspace ? 0.16 : 0.10)
            StarField()
            vignette
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: mood == .dusk
                ? [Color(hex: 0x0B0E14), Color(hex: 0x0A0B10), HaloColor.void]
                : [Color(hex: 0x070B11), Color(hex: 0x04070B), HaloColor.void],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var haloGlow: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [HaloColor.ice.opacity(0.11), HaloColor.iceDeep.opacity(0.035), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: proxy.size.width * 0.62
                )
                .frame(width: proxy.size.width * 1.3, height: proxy.size.width * 1.3)
                .position(
                    x: proxy.size.width * 0.58,
                    y: proxy.size.height * (mood == .workspace ? 0.34 : 0.28)
                )
                .blur(radius: 30)

                RadialGradient(
                    colors: [HaloColor.violet.opacity(0.055), .clear],
                    center: .center,
                    startRadius: 4,
                    endRadius: proxy.size.width * 0.42
                )
                .frame(width: proxy.size.width, height: proxy.size.width)
                .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.66)
                .blur(radius: 36)
            }
        }
    }

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, .clear, Color.black.opacity(0.42)],
            center: .center,
            startRadius: 80,
            endRadius: 520
        )
        .blendMode(.multiply)
    }
}

struct HaloHomeBackground: View {
    @State private var glowPulse = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let apexY = height * 0.565
            let sphereDiameter = width * 2.35
            let sphereCenterY = apexY + sphereDiameter * 0.5

            ZStack {
                Color(hex: 0x020306)

                LinearGradient(
                    colors: [Color(hex: 0x04070D), Color(hex: 0x020408), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                StarField(count: 58, seed: 0x0FA10)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.45), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.52)
                        )
                    )

                // Soft silver atmospheric halo radiating above the sphere apex
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(glowPulse ? 0.30 : 0.22),
                                Color(hex: 0xC9D6E8).opacity(glowPulse ? 0.16 : 0.11),
                                Color(hex: 0x6F84A3).opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.62
                        )
                    )
                    .frame(width: width * 1.55, height: height * 0.34)
                    .position(x: width * 0.5, y: apexY - height * 0.015)
                    .blur(radius: 28)

                // Smooth silver sphere body with brushed metallic curvature
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xE6ECF5).opacity(0.34),
                                Color(hex: 0x8E9BAE).opacity(0.24),
                                Color(hex: 0x3D4654).opacity(0.32),
                                Color(hex: 0x151A22),
                                Color(hex: 0x06080C),
                                .black
                            ],
                            center: UnitPoint(x: 0.5, y: 0.012),
                            startRadius: 2,
                            endRadius: sphereDiameter * 0.30
                        )
                    )
                    .frame(width: sphereDiameter, height: sphereDiameter)
                    .position(x: width * 0.5, y: sphereCenterY)

                // Soft inner rim sheen wrapping inside the silver sphere edge
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.62),
                                .init(color: Color(hex: 0xBCC8D9).opacity(0.20), location: 0.70),
                                .init(color: Color.white.opacity(glowPulse ? 0.52 : 0.38), location: 0.75),
                                .init(color: Color(hex: 0xBCC8D9).opacity(0.20), location: 0.80),
                                .init(color: .clear, location: 0.88)
                            ]),
                            center: .center
                        ),
                        lineWidth: 10
                    )
                    .frame(width: sphereDiameter - 10, height: sphereDiameter - 10)
                    .position(x: width * 0.5, y: sphereCenterY)
                    .blur(radius: 6)

                // Outer silver rim bloom
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.63),
                                .init(color: Color(hex: 0xD0DAE8).opacity(0.24), location: 0.70),
                                .init(color: Color.white.opacity(glowPulse ? 0.72 : 0.56), location: 0.75),
                                .init(color: Color(hex: 0xD0DAE8).opacity(0.24), location: 0.80),
                                .init(color: .clear, location: 0.87)
                            ]),
                            center: .center
                        ),
                        lineWidth: 5
                    )
                    .frame(width: sphereDiameter, height: sphereDiameter)
                    .position(x: width * 0.5, y: sphereCenterY)
                    .blur(radius: 4)

                // Crisp specular silver horizon edge
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.62),
                                .init(color: Color(hex: 0xC6D1E0).opacity(0.32), location: 0.69),
                                .init(color: Color.white.opacity(0.95), location: 0.75),
                                .init(color: Color(hex: 0xC6D1E0).opacity(0.32), location: 0.81),
                                .init(color: .clear, location: 0.88)
                            ]),
                            center: .center
                        ),
                        lineWidth: 1.4
                    )
                    .frame(width: sphereDiameter, height: sphereDiameter)
                    .position(x: width * 0.5, y: sphereCenterY)

                // Specular highlight right on the silver sphere apex
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(glowPulse ? 0.92 : 0.76),
                                Color(hex: 0xE6EEF8).opacity(0.42),
                                Color(hex: 0xB8C6DA).opacity(0.14),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.20
                        )
                    )
                    .frame(width: width * 0.42, height: 30)
                    .position(x: width * 0.5, y: apexY)
                    .blur(radius: 5)

                RadialGradient(
                    colors: [.clear, .clear, Color.black.opacity(0.45)],
                    center: .center,
                    startRadius: 110,
                    endRadius: max(width, height) * 0.76
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct HorizonGlow: View {
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(opacity), HaloColor.ice.opacity(opacity * 0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: proxy.size.width * 0.55
                        )
                    )
                    .frame(width: proxy.size.width * 1.5, height: proxy.size.height * 0.26)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.78)
                    .blur(radius: 46)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(opacity * 0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.6)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.72)
                    .blur(radius: 0.4)
            }
        }
    }
}

struct StarField: View {
    private let stars: [HaloStar]

    init(count: Int = 74, seed: UInt64 = 0xA11CE) {
        stars = HaloStar.makeStars(count: count, seed: seed)
    }

    var body: some View {
        Canvas { context, size in
            for star in stars {
                let rect = CGRect(
                    x: star.x * size.width,
                    y: star.y * size.height,
                    width: star.radius,
                    height: star.radius
                )
                context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(star.opacity)))
            }
        }
        .blendMode(.screen)
        .opacity(0.7)
    }
}

struct HaloStar {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let opacity: Double

    static func makeStars(count: Int, seed: UInt64) -> [HaloStar] {
        var generator = HaloSeededGenerator(seed: seed)
        return (0..<count).map { _ in
            HaloStar(
                x: CGFloat.random(in: 0.02...0.98, using: &generator),
                y: CGFloat.random(in: 0.01...0.72, using: &generator),
                radius: CGFloat.random(in: 0.5...1.6, using: &generator),
                opacity: Double.random(in: 0.08...0.52, using: &generator)
            )
        }
    }
}

struct HaloSeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
