//
//  ControlCenterView.swift
//  HaloSpace V3
//

import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var permissions: PermissionManager
    @EnvironmentObject private var windows: HaloWindowManager

    @State private var appeared = false

    var body: some View {
        ZStack {
            HaloAmbientBackground(mood: .workspace)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    contextRow
                    workspaceCard
                    statusCard
                    dashboardGrid
                    footerNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Control Center")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !appeared else { return }
            withAnimation(HaloMotion.gentle) { appeared = true }
        }
    }

    private var contextRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Control. Customize. Experience.")
                .font(HaloFont.callout)
                .foregroundStyle(HaloColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                Circle()
                    .fill(engineStatusColor)
                    .frame(width: 5, height: 5)
                Text(engineStatusText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(HaloColor.textSecondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                Capsule().fill(Color.white.opacity(0.045))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6))
            )
            .accessibilityLabel("Spatial engine status: \(engineStatusText)")
        }
        .padding(.top, 4)
    }

    private var workspaceCard: some View {
        Button {
            HaloHaptics.impact(.medium, enabled: settings.hapticsEnabled)
            launchWorkspace()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                SpatialWorkspacePreview()
                    .frame(height: 188)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        Text("LIVE WORKSPACE")
                            .font(.system(size: 8.5, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(HaloColor.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.32)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.6))
                            .padding(12)
                    }

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Spatial Workspace")
                            .font(HaloFont.title2)
                            .foregroundStyle(HaloColor.textPrimary)
                        Text("A new way to work, browse and create.")
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textSecondary)
                    }
                    Spacer(minLength: 4)
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.13))
                            .frame(width: 48, height: 48)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(HaloColor.textPrimary)
                    }
                    .shadow(color: HaloColor.ice.opacity(0.10), radius: 12)
                }
                .padding(16)
                .padding(.bottom, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                    .fill(HaloColor.windowGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous))
            .shadow(color: Color.black.opacity(0.4), radius: 24, y: 14)
        }
        .buttonStyle(HaloPressStyle(scale: 0.985))
        .accessibilityLabel("Open your spatial workspace")
        .accessibilityIdentifier("controlCenter.workspace")
    }

    private var statusCard: some View {
        HStack(spacing: 0) {
            statusMetric(
                value: "\(windows.visibleWindows.count)",
                label: "Open windows",
                systemImage: "rectangle.on.rectangle"
            )
            metricDivider
            statusMetric(
                value: settings.handTrackingEnabled ? "On" : "Off",
                label: "Hand tracking",
                systemImage: "hand.point.up.left"
            )
            metricDivider
            statusMetric(
                value: windows.visibleWindows.isEmpty ? "Empty" : "Saved",
                label: "Workspace",
                systemImage: "internaldrive"
            )
        }
        .padding(.vertical, 12)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                tint: Color.white.opacity(0.025),
                strokeOpacity: 0.10,
                shadowRadius: 14
            )
        )
    }

    private func statusMetric(value: String, label: String, systemImage: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HaloColor.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HaloColor.textPrimary)
            Text(label)
                .font(.system(size: 9.5, weight: .regular))
                .foregroundStyle(HaloColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 0.6, height: 34)
    }

    private var dashboardGrid: some View {
        VStack(spacing: 10) {
            HaloSectionLabel(title: "Dashboard")
                .padding(.top, 2)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                DashboardCard(
                    title: "Spatial Settings",
                    subtitle: "Mode, placement, environment",
                    systemName: "viewfinder",
                    accent: .ice
                ) {
                    router.openSettings(.spatial)
                }
                DashboardCard(
                    title: "Window Manager",
                    subtitle: "Arrange and restore windows",
                    systemName: "rectangle.3.group",
                    accent: .violet
                ) {
                    router.openSettings(.windowManager)
                }
                DashboardCard(
                    title: "Applications",
                    subtitle: "Browse built-in spatial apps",
                    systemName: "square.grid.2x2",
                    accent: .amber
                ) {
                    router.selectedTab = .apps
                }
                DashboardCard(
                    title: "Appearance",
                    subtitle: "Glass, tint and transparency",
                    systemName: "circle.lefthalf.filled",
                    accent: .mint
                ) {
                    router.openSettings(.appearance)
                }
            }
        }
    }

    private var footerNote: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock")
                .font(.system(size: 9))
            Text("Workspace data is stored locally on this iPhone.")
                .font(.system(size: 10.5))
        }
        .foregroundStyle(HaloColor.textTertiary)
        .padding(.top, 2)
    }

    private var engineStatusColor: Color {
        if !permissions.arSupported { return HaloColor.warning }
        if permissions.camera == .authorized { return HaloColor.success }
        if permissions.camera == .denied || permissions.camera == .restricted { return HaloColor.danger }
        return HaloColor.textTertiary
    }

    private var engineStatusText: String {
        if !permissions.arSupported { return "Preview" }
        switch permissions.camera {
        case .authorized: return "Ready"
        case .notDetermined: return "Standby"
        case .denied, .restricted: return "No camera"
        }
    }

    private func launchWorkspace() {
        let mode: HaloLaunchMode
        switch settings.defaultLaunchMode {
        case .vr:
            mode = .vr
        case .ultraFast:
            mode = .ultraFast
        case .ar:
            mode = settings.performanceMode ? .ultraFast : .ar
        }
        appState.launchSelectedExperience(mode)
    }
}

private struct DashboardCard: View {
    let title: String
    let subtitle: String
    let systemName: String
    let accent: HaloAccent
    let action: () -> Void

    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        Button {
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HaloIconTile(systemName: systemName, accent: accent, size: 34)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HaloColor.textTertiary)
                }
                Spacer(minLength: 14)
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(HaloColor.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 26, alignment: .top)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                HaloGlassSurface(
                    shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                    tint: Color.white.opacity(0.028),
                    strokeOpacity: 0.11,
                    shadowRadius: 14
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous))
        }
        .buttonStyle(HaloPressStyle(scale: 0.975))
    }
}

struct SpatialWorkspacePreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x0B1118),
                    Color(hex: 0x131D29),
                    Color(hex: 0x080B10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HorizonLines()
                .stroke(Color.white.opacity(0.055), lineWidth: 0.6)
                .offset(y: 58)

            RadialGradient(
                colors: [HaloColor.ice.opacity(0.17), .clear],
                center: UnitPoint(x: 0.52, y: 0.45),
                startRadius: 2,
                endRadius: 170
            )
            .blur(radius: 14)

            previewWindow(width: 156, height: 106, title: "Halo Notes", icon: "note.text", accent: .amber)
                .rotation3DEffect(.degrees(-8), axis: (x: 0, y: 1, z: 0))
                .offset(x: -66, y: floating ? -4 : 2)
                .zIndex(1)

            previewWindow(width: 176, height: 118, title: "Halo Browser", icon: "safari", accent: .ice)
                .rotation3DEffect(.degrees(4), axis: (x: 0, y: 1, z: 0))
                .offset(x: 58, y: floating ? 8 : -2)
                .zIndex(2)

            HStack(spacing: 6) {
                Circle().fill(HaloColor.success).frame(width: 4, height: 4)
                Text("Spatial engine")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(HaloColor.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.30)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
            .offset(x: -105, y: 76)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Animation.easeInOut(duration: 4.6).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }

    private func previewWindow(width: CGFloat, height: CGFloat, title: String, icon: String, accent: HaloAccent) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 7.5, weight: .semibold))
                    .foregroundStyle(HaloColor.accent(accent))
                Text(title)
                    .font(.system(size: 7.5, weight: .semibold))
                    .foregroundStyle(HaloColor.textSecondary)
                Spacer()
                HStack(spacing: 3) {
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 4, height: 4)
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 4, height: 4)
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 20)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: width * 0.52, height: 5)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.10))
                    .frame(width: width * 0.70, height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: width * 0.44, height: 4)
                Spacer()
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HaloColor.accent(accent).opacity(0.30))
                        .frame(width: 26, height: 11)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 34, height: 11)
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: 0x0E141C).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 14, y: 8)
        )
    }
}

private struct HorizonLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.minY + 34)
        for index in -7...7 {
            let x = rect.midX + CGFloat(index) * rect.width / 5
            path.move(to: center)
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for step in 0..<7 {
            let progress = CGFloat(step) / 6
            let y = center.y + pow(progress, 2.1) * (rect.maxY - center.y)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}
