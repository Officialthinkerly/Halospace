//
//  HomeView.swift
//  HaloSpace V3
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var permissions: PermissionManager

    @State private var logoRevealed = false
    @State private var buttonsRevealed = false

    var body: some View {
        NavigationStack(path: $router.homePath) {
            GeometryReader { proxy in
                ZStack {
                    HaloHomeBackground()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 32)

                            logoBlock
                                .opacity(logoRevealed ? 1 : 0)
                                .scaleEffect(logoRevealed ? 1 : 0.94)
                                .offset(y: logoRevealed ? 0 : 12)

                            Spacer(minLength: 48)

                            enterButton
                                .opacity(buttonsRevealed ? 1 : 0)
                                .offset(y: buttonsRevealed ? 0 : 18)

                            appsButton
                                .padding(.top, 12)
                                .opacity(buttonsRevealed ? 1 : 0)
                                .offset(y: buttonsRevealed ? 0 : 22)

                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                        router.openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .accessibilityLabel("Open Settings")
                    .accessibilityIdentifier("home.settings")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    versionBadge
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .controlCenter:
                    ControlCenterView()
                case .windowManager:
                    WindowManagerSettingsView()
                }
            }
        }
        .onAppear {
            runEntranceAnimation()
        }
    }

    private func runEntranceAnimation() {
        guard !logoRevealed else { return }
        withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
            logoRevealed = true
        }
        withAnimation(.spring(response: 0.60, dampingFraction: 0.85).delay(0.10)) {
            buttonsRevealed = true
        }
    }

    private var logoBlock: some View {
        VStack(spacing: 0) {
            Image("HaloLogoFull")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 292)
                .shadow(color: Color.white.opacity(0.14), radius: 26)
                .accessibilityLabel("HaloSpace")

            Text(HaloBrand.tagline)
                .font(.system(size: 14.5, weight: .regular))
                .tracking(0.25)
                .foregroundStyle(HaloColor.textSecondary)
                .padding(.top, -6)
        }
        .frame(maxWidth: .infinity)
    }

    private var enterButton: some View {
        Button {
            HaloHaptics.impact(.medium, enabled: settings.hapticsEnabled)
            appState.launchSelectedExperience(settings.defaultLaunchMode)
        } label: {
            ZStack {
                HStack(spacing: 10) {
                    HaloRocketIcon()
                        .frame(width: 19, height: 19)
                    Text("Enter HaloSpace")
                        .font(.system(size: 16.5, weight: .semibold))
                }

                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.88))
                }
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color(hex: 0x9AA9BF).opacity(0.16),
                                    Color(hex: 0x202734).opacity(0.32),
                                    Color.white.opacity(0.10)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.26),
                                    .clear
                                ],
                                center: UnitPoint(x: 0.28, y: 0.12),
                                startRadius: 2,
                                endRadius: 140
                            )
                        )

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.76),
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.42)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.05
                        )
                }
                .shadow(color: Color.white.opacity(0.10), radius: 14, x: 0, y: -2)
                .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(HaloPressStyle(scale: 0.98))
        .accessibilityIdentifier("home.enter")
    }

    private var appsButton: some View {
        Button {
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            router.selectedTab = .apps
        } label: {
            ZStack {
                HStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                    Text("Apps")
                        .font(.system(size: 16, weight: .medium))
                }

                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            }
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.black.opacity(0.34),
                                    Color(hex: 0x1A202B).opacity(0.22)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.32),
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.95
                        )
                }
                .shadow(color: Color.black.opacity(0.42), radius: 16, x: 0, y: 8)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(HaloPressStyle(scale: 0.98))
        .accessibilityIdentifier("home.apps")
    }

    private var versionBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
                .shadow(color: statusColor.opacity(0.6), radius: 3)
            Text(HaloBrand.versionLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HaloColor.textSecondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.055))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.6))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("HaloSpace version \(HaloBrand.version), \(permissions.statusSummary)")
    }

    private var statusColor: Color {
        if !permissions.arSupported { return HaloColor.warning }
        return permissions.camera.isAuthorized ? HaloColor.success : HaloColor.textTertiary
    }
}

private struct HaloRocketIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stroke = StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round)

            // Sleek diagonal rocket silhouette pointing top-right
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: w * 0.86, y: h * 0.14))
            bodyPath.addQuadCurve(
                to: CGPoint(x: w * 0.28, y: h * 0.58),
                control: CGPoint(x: w * 0.48, y: h * 0.16)
            )
            bodyPath.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
            bodyPath.addQuadCurve(
                to: CGPoint(x: w * 0.86, y: h * 0.14),
                control: CGPoint(x: w * 0.84, y: h * 0.52)
            )
            context.stroke(bodyPath, with: .foreground, style: stroke)

            // Porthole window
            let portRect = CGRect(x: w * 0.53, y: h * 0.34, width: w * 0.14, height: h * 0.14)
            context.stroke(Path(ellipseIn: portRect), with: .foreground, style: stroke)

            // Left & bottom fins
            var fins = Path()
            fins.move(to: CGPoint(x: w * 0.34, y: h * 0.48))
            fins.addLine(to: CGPoint(x: w * 0.18, y: h * 0.52))
            fins.addLine(to: CGPoint(x: w * 0.28, y: h * 0.60))

            fins.move(to: CGPoint(x: w * 0.52, y: h * 0.66))
            fins.addLine(to: CGPoint(x: w * 0.48, y: h * 0.82))
            fins.addLine(to: CGPoint(x: w * 0.40, y: h * 0.72))
            context.stroke(fins, with: .foreground, style: stroke)

            // Exhaust flame
            var flame = Path()
            flame.move(to: CGPoint(x: w * 0.26, y: h * 0.72))
            flame.addLine(to: CGPoint(x: w * 0.14, y: h * 0.86))
            flame.move(to: CGPoint(x: w * 0.32, y: h * 0.78))
            flame.addLine(to: CGPoint(x: w * 0.24, y: h * 0.88))
            context.stroke(flame, with: .foreground, style: stroke)
        }
    }
}
