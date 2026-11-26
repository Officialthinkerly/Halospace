//
//  SettingsView.swift
//  HaloSpace V3
//

import SwiftUI

struct SettingsSearchEntry: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let route: SettingsRoute
    let keywords: [String]
}

struct SettingsView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var permissions: PermissionManager

    @State private var searchText = ""
    @Namespace private var modeHighlight

    var body: some View {
        NavigationStack(path: $router.settingsPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if searchText.isEmpty {
                        brandCard
                        launchModeSection
                        generalSection
                        advancedSection
                        footer
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background {
                HaloAmbientBackground(mood: .workspace)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search settings"
            )
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(for: route)
            }
        }
        .onAppear {
            permissions.refresh()
        }
    }

    private var launchModeSection: some View {
        VStack(spacing: 9) {
            HaloSectionLabel(title: "Launch Mode", trailing: settings.defaultLaunchMode.compactTitle)

            HStack(spacing: 0) {
                ForEach(Array(HaloLaunchMode.allCases.enumerated()), id: \.offset) { index, mode in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 0.7, height: 52)
                    }
                    modeButton(mode)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.45))

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x121720).opacity(0.84),
                                    Color(hex: 0x090C11).opacity(0.90)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.10)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.85
                        )
                }
                .shadow(color: Color.black.opacity(0.40), radius: 18, x: 0, y: 8)
            )
        }
    }

    private func modeButton(_ mode: HaloLaunchMode) -> some View {
        let selected = settings.defaultLaunchMode == mode
        let lines = modeLines(for: mode)

        return Button {
            guard !selected else { return }
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            withAnimation(HaloMotion.snappy) {
                settings.selectLaunchMode(mode)
            }
        } label: {
            VStack(spacing: 8) {
                modeIcon(for: mode)
                    .frame(height: 22)

                VStack(spacing: 1) {
                    Text(lines.top)
                        .font(.system(size: 13, weight: selected ? .semibold : .medium))
                    Text(lines.bottom)
                        .font(.system(size: 13, weight: selected ? .medium : .regular))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .foregroundStyle(selected ? Color.white : Color.white.opacity(0.56))
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6)
                        )
                        .matchedGeometryEffect(id: "settings.modeSelection", in: modeHighlight)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.compactTitle)
        .accessibilityHint(mode.subtitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("settings.mode.\(mode.rawValue)")
    }

    @ViewBuilder
    private func modeIcon(for mode: HaloLaunchMode) -> some View {
        switch mode {
        case .ar:
            ZStack {
                Image(systemName: "viewfinder")
                    .font(.system(size: 19, weight: .semibold))
                Image(systemName: "arkit")
                    .font(.system(size: 8.5, weight: .bold))
            }
        case .vr:
            SettingsVRHeadsetIcon()
                .frame(width: 24, height: 17)
        case .ultraFast:
            Image(systemName: "bolt")
                .font(.system(size: 19, weight: .semibold))
        }
    }

    private func modeLines(for mode: HaloLaunchMode) -> (top: String, bottom: String) {
        switch mode {
        case .ar: return ("AR", "Mode")
        case .vr: return ("VR", "Mode")
        case .ultraFast: return ("Ultra", "Fast")
        }
    }

    private var brandCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 13) {
                HaloLogoMark(size: 44, animated: false, glowIntensity: 0.55)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 3) {
                    Text("HaloSpace")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(HaloColor.textPrimary)
                    HStack(spacing: 6) {
                        Text("v\(HaloBrand.version)")
                            .font(HaloFont.caption)
                            .foregroundStyle(HaloColor.ice)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(HaloColor.ice.opacity(0.10)))
                        Text("Build \(HaloBrand.buildNumber)")
                            .font(HaloFont.caption)
                            .foregroundStyle(HaloColor.textTertiary)
                    }
                }
                Spacer()
                Circle()
                    .fill(permissions.camera.isAuthorized ? HaloColor.success.opacity(0.8) : HaloColor.textTertiary.opacity(0.5))
                    .frame(width: 7, height: 7)
                    .shadow(color: permissions.camera.isAuthorized ? HaloColor.success.opacity(0.7) : .clear, radius: 4)
            }

            Text(HaloBrand.shortDescription)
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x101821), Color(hex: 0x0A0F15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [HaloColor.ice.opacity(0.10), .clear],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 240
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.32), radius: 18, y: 10)
        )
    }

    private var generalSection: some View {
        VStack(spacing: 9) {
            HaloSectionLabel(title: "General")

            HaloGroupedRows {
                Group {
                    HaloNavigationRow(
                        systemName: "viewfinder",
                        title: "Spatial Experience",
                        subtitle: "\(settings.defaultLaunchMode.compactTitle) · \(settings.windowPlacement.title)",
                        accent: .ice
                    ) {
                        navigate(to: .spatial)
                    }
                    HaloRowDivider()
                    HaloNavigationRow(
                        systemName: "hand.point.up.left",
                        title: "Gestures & Controls",
                        subtitle: settings.gesturesEnabled ? "Pinch tracking · \(settings.handTrackingRate.title)" : "Gestures disabled",
                        accent: .amber
                    ) {
                        navigate(to: .gestures)
                    }
                    HaloRowDivider()
                    HaloNavigationRow(
                        systemName: "circle.lefthalf.filled",
                        title: "Appearance",
                        subtitle: "\(settings.windowTint.title) · \(Int(settings.uiTransparency * 100))% glass",
                        accent: .violet
                    ) {
                        navigate(to: .appearance)
                    }
                }
                Group {
                    HaloRowDivider()
                    HaloNavigationRow(
                        systemName: "lock.shield",
                        title: "Privacy & Security",
                        subtitle: "Camera \(permissions.camera.title) · On-device processing",
                        accent: .mint
                    ) {
                        navigate(to: .privacy)
                    }
                    HaloRowDivider()
                    HaloNavigationRow(
                        systemName: "rectangle.3.group",
                        title: "Window Manager",
                        subtitle: "\(appState.windowManager.windows.count) saved windows",
                        accent: .silver
                    ) {
                        navigate(to: .windowManager)
                    }
                }
                HaloRowDivider()
                HaloNavigationRow(
                    systemName: "slider.horizontal.3",
                    title: "Control Center",
                    subtitle: "Workspace status and quick actions",
                    accent: .ice
                ) {
                    navigate(to: .controlCenter)
                }
            }
        }
    }

    private var advancedSection: some View {
        VStack(spacing: 9) {
            HaloSectionLabel(title: "Advanced")

            HaloGroupedRows {
                if settings.developerModeUnlocked {
                    HaloNavigationRow(
                        systemName: "hammer",
                        title: "Developer Options",
                        subtitle: "Diagnostics, sessions and rendering",
                        accent: .amber
                    ) {
                        navigate(to: .developer)
                    }
                    HaloRowDivider()
                }
                HaloNavigationRow(
                    systemName: "info.circle",
                    title: "About HaloSpace",
                    subtitle: "Version, build and privacy",
                    accent: .ice
                ) {
                    navigate(to: .about)
                }
            }
        }
    }

    private var searchEntries: [SettingsSearchEntry] {
        var entries: [SettingsSearchEntry] = [
            SettingsSearchEntry(
                id: "spatial",
                title: "Spatial Experience",
                subtitle: "Default mode, environment, window placement",
                route: .spatial,
                keywords: ["ar", "vr", "mode", "environment", "placement", "workspace", "plane"]
            ),
            SettingsSearchEntry(
                id: "gestures",
                title: "Gestures & Controls",
                subtitle: "Hand tracking, pinch sensitivity, haptics",
                route: .gestures,
                keywords: ["hand", "pinch", "drag", "gesture", "sensitivity", "haptic", "touch"]
            ),
            SettingsSearchEntry(
                id: "appearance",
                title: "Appearance",
                subtitle: "Window tint, transparency, labels",
                route: .appearance,
                keywords: ["glass", "tint", "transparency", "theme", "appearance", "window"]
            ),
            SettingsSearchEntry(
                id: "privacy",
                title: "Privacy & Security",
                subtitle: "Camera permission, local data, hand tracking",
                route: .privacy,
                keywords: ["camera", "permission", "privacy", "data", "security", "local", "delete"]
            ),
            SettingsSearchEntry(
                id: "windows",
                title: "Window Manager",
                subtitle: "Open windows, workspace layout",
                route: .windowManager,
                keywords: ["window", "close", "minimize", "arrange", "workspace", "reset"]
            ),
            SettingsSearchEntry(
                id: "controlCenter",
                title: "Control Center",
                subtitle: "Workspace status and quick actions",
                route: .controlCenter,
                keywords: ["control", "center", "dashboard", "workspace", "status", "quick"]
            ),
            SettingsSearchEntry(
                id: "about",
                title: "About HaloSpace",
                subtitle: "Version, build, acknowledgements",
                route: .about,
                keywords: ["version", "build", "about", "credits", "privacy"]
            )
        ]
        if settings.developerModeUnlocked {
            entries.append(
                SettingsSearchEntry(
                    id: "developer",
                    title: "Developer Options",
                    subtitle: "AR session, diagnostics, FPS, logging",
                    route: .developer,
                    keywords: ["developer", "diagnostics", "fps", "ar", "session", "debug", "log", "lidar"]
                )
            )
        }
        return entries
    }

    private var searchResults: some View {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = searchEntries.filter { entry in
            entry.title.lowercased().contains(query)
                || entry.subtitle.lowercased().contains(query)
                || entry.keywords.contains { $0.contains(query) }
        }

        return VStack(spacing: 9) {
            HaloSectionLabel(title: "Results", trailing: "\(matches.count)")
            if matches.isEmpty {
                HaloEmptyState(
                    systemName: "magnifyingglass",
                    title: "No matching settings",
                    message: "Try searching for camera, gesture, window or privacy."
                )
            } else {
                HaloGroupedRows {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { HaloRowDivider() }
                        HaloNavigationRow(
                            systemName: icon(for: entry.route),
                            title: entry.title,
                            subtitle: entry.subtitle
                        ) {
                            navigate(to: entry.route)
                            searchText = ""
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 5) {
            HaloWordmark(size: 14)
                .foregroundStyle(HaloColor.textTertiary)
            Text("Designed for iPhone · On-device spatial processing")
                .font(.system(size: 10))
                .foregroundStyle(HaloColor.textTertiary)
        }
        .padding(.top, 6)
    }

    private func navigate(to route: SettingsRoute) {
        HaloHaptics.selection(enabled: settings.hapticsEnabled)
        if !searchText.isEmpty {
            searchText = ""
        }
        router.settingsPath.append(route)
    }

    private func icon(for route: SettingsRoute) -> String {
        switch route {
        case .spatial: return "viewfinder"
        case .gestures: return "hand.point.up.left"
        case .appearance: return "circle.lefthalf.filled"
        case .privacy: return "lock.shield"
        case .windowManager: return "rectangle.3.group"
        case .controlCenter: return "slider.horizontal.3"
        case .developer: return "hammer"
        case .about: return "info.circle"
        }
    }

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        switch route {
        case .spatial:
            SpatialSettingsView()
        case .gestures:
            GesturesSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .privacy:
            PrivacySecurityView()
        case .windowManager:
            WindowManagerSettingsView()
        case .controlCenter:
            ControlCenterView()
        case .developer:
            DeveloperOptionsView()
        case .about:
            AboutHaloSpaceView()
        }
    }
}

private struct SettingsVRHeadsetIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stroke = StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round)

            var outline = Path()
            outline.move(to: CGPoint(x: w * 0.18, y: h * 0.12))
            outline.addLine(to: CGPoint(x: w * 0.82, y: h * 0.12))
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.94, y: h * 0.42),
                control: CGPoint(x: w * 0.94, y: h * 0.12)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.76, y: h * 0.88),
                control: CGPoint(x: w * 0.94, y: h * 0.88)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.58, y: h * 0.70),
                control: CGPoint(x: w * 0.66, y: h * 0.88)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.42, y: h * 0.70),
                control: CGPoint(x: w * 0.50, y: h * 0.56)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.24, y: h * 0.88),
                control: CGPoint(x: w * 0.34, y: h * 0.88)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.06, y: h * 0.42),
                control: CGPoint(x: w * 0.06, y: h * 0.88)
            )
            outline.addQuadCurve(
                to: CGPoint(x: w * 0.18, y: h * 0.12),
                control: CGPoint(x: w * 0.06, y: h * 0.12)
            )
            outline.closeSubpath()
            context.stroke(outline, with: .foreground, style: stroke)

            let dotSize = min(w, h) * 0.15
            let leftDot = CGRect(x: w * 0.28, y: h * 0.42, width: dotSize, height: dotSize)
            let rightDot = CGRect(x: w * 0.62, y: h * 0.42, width: dotSize, height: dotSize)
            context.fill(Path(ellipseIn: leftDot), with: .foreground)
            context.fill(Path(ellipseIn: rightDot), with: .foreground)
        }
    }
}
