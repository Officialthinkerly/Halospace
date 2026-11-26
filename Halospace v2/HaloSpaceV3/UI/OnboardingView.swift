//
//  OnboardingView.swift
//  HaloSpace V3
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "HALOSPACE",
            title: "Your space,\nexpanded.",
            message: "Turn the room around you into a quiet, floating workspace. Windows stay anchored where you place them.",
            systemImage: nil
        ),
        OnboardingPage(
            eyebrow: "NATURAL INTERACTION",
            title: "Reach in.\nMove freely.",
            message: "Use touch to move and resize windows, or pinch your thumb and index finger to work with your free hand.",
            systemImage: "hand.point.up.left"
        ),
        OnboardingPage(
            eyebrow: "PRIVATE BY DESIGN",
            title: "On this iPhone.\nAnd nowhere else.",
            message: "Camera frames and hand tracking are processed locally. HaloSpace never uploads your camera feed or hand data.",
            systemImage: "lock.shield"
        )
    ]

    var body: some View {
        ZStack {
            HaloAmbientBackground(mood: .dusk)

            VStack(spacing: 0) {
                HStack {
                    HaloWordmark(size: 19, showsDot: false)
                        .foregroundStyle(HaloColor.textPrimary)
                    Spacer()
                    Button("Skip") { finish() }
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                }
                .padding(.horizontal, 26)
                .padding(.top, 10)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 22) {
                    HStack(spacing: 7) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? HaloColor.textPrimary : Color.white.opacity(0.16))
                                .frame(width: index == page ? 20 : 6, height: 4)
                                .animation(reduceMotion ? nil : HaloMotion.snappy, value: page)
                        }
                    }

                    Button {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : HaloMotion.gentle) {
                                page += 1
                            }
                            HaloHaptics.selection(enabled: true)
                        } else {
                            finish()
                        }
                    } label: {
                        Text(page == pages.count - 1 ? "Begin" : "Continue")
                            .font(HaloFont.headline)
                            .foregroundStyle(HaloColor.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                                            .fill(Color.white.opacity(0.10))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.9)
                                    )
                            )
                    }
                    .buttonStyle(HaloPressStyle(reduceMotion: reduceMotion))
                    .padding(.horizontal, 26)
                }
                .padding(.bottom, 26)
            }
        }
        .interactiveDismissDisabled()
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            if let systemImage = item.systemImage {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [HaloColor.ice.opacity(0.16), .clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 100
                            )
                        )
                        .frame(width: 210, height: 210)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
                        .frame(width: 112, height: 112)
                    Image(systemName: systemImage)
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(HaloColor.frost)
                }
                .frame(height: 226)
            } else {
                HaloLogoMark(size: 132, animated: true, glowIntensity: 0.9)
                    .frame(height: 226)
            }

            VStack(spacing: 12) {
                Text(item.eyebrow)
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(2.1)
                    .foregroundStyle(HaloColor.textTertiary)

                Text(item.title)
                    .font(.system(size: 37, weight: .bold, design: .default))
                    .tracking(-0.8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineSpacing(1)

                Text(item.message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(HaloColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3.5)
                    .frame(maxWidth: 320)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 24)
        }
    }

    private func finish() {
        HaloHaptics.impact(.medium, enabled: true)
        onFinish()
    }
}

private struct OnboardingPage {
    let eyebrow: String
    let title: String
    let message: String
    let systemImage: String?
}
