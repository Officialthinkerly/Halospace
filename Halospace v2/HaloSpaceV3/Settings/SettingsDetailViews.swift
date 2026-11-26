//
//  SettingsDetailViews.swift
//  HaloSpace V3
//

import SwiftUI

// MARK: - Spatial

struct SpatialSettingsView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windows: HaloWindowManager
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var permissions: PermissionManager

    var body: some View {
        HaloSettingsPage(
            title: "Spatial Experience",
            subtitle: "Control how HaloSpace builds and presents your spatial workspace."
        ) {
            VStack(spacing: 9) {
                HaloSectionLabel(title: "Launch")
                HaloGroupedRows {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default launch mode")
                                .font(HaloFont.bodyMedium)
                                .foregroundStyle(HaloColor.textPrimary)
                            Spacer()
                        }
                        HaloSegmentedOptions(
                            options: HaloLaunchMode.allCases,
                            label: { $0.compactTitle },
                            selection: Binding(
                                get: { settings.defaultLaunchMode },
                                set: { settings.selectLaunchMode($0) }
                            )
                        )
                        Text(settings.defaultLaunchMode.subtitle)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textTertiary)
                    }
                    .padding(.horizontal, HaloSpacing.md)
                    .padding(.vertical, 13)

                    HaloRowDivider()

                    HaloToggleRow(
                        systemName: "bolt",
                        title: "Ultra Fast processing",
                        subtitle: "Reduce rendering and hand-tracking frequency to preserve battery.",
                        accent: .amber,
                        isOn: $settings.performanceMode
                    )
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Environment")
                HaloGroupedRows {
                    ForEach(Array(HaloEnvironmentStyle.allCases.enumerated()), id: \.offset) { index, style in
                        if index > 0 { HaloRowDivider() }
                        HaloRadioRow(
                            title: style.title,
                            detail: style.detail,
                            isSelected: settings.environmentStyle == style
                        ) {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            settings.environmentStyle = style
                        }
                    }
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Windows")
                HaloGroupedRows {
                    ForEach(Array(HaloWindowPlacement.allCases.enumerated()), id: \.offset) { index, placement in
                        if index > 0 { HaloRowDivider() }
                        HaloRadioRow(
                            title: placement.title,
                            detail: placement.detail,
                            isSelected: settings.windowPlacement == placement
                        ) {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            settings.windowPlacement = placement
                        }
                    }
                    HaloRowDivider()
                    HaloSliderRow(
                        title: "Window scale",
                        subtitle: "Adjust the physical size of new windows.",
                        valueLabel: "\(Int(settings.windowScale * 100))%",
                        value: $settings.windowScale,
                        range: 0.8...1.25,
                        step: 0.05
                    )
                    HaloRowDivider()
                    HaloToggleRow(
                        systemName: "square.3.layers.3d",
                        title: "Plane detection",
                        subtitle: permissions.arSupported
                            ? "Use detected horizontal surfaces to help place windows."
                            : "Requires a supported ARKit device.",
                        accent: .ice,
                        isOn: $settings.planeDetectionEnabled
                    )
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Workspace")
                HStack(spacing: 10) {
                    HaloActionTile(title: "Enter Space", systemName: "cube.transparent", accent: .ice) {
                        appState.launchSelectedExperience(settings.defaultLaunchMode)
                    }
                    HaloActionTile(
                        title: "Tidy",
                        systemName: "rectangle.3.group",
                        accent: .violet,
                        isEnabled: !windows.visibleWindows.isEmpty
                    ) {
                        windows.tidyWorkspace()
                    }
                    HaloActionTile(title: "Windows", systemName: "rectangle.on.rectangle", accent: .silver) {
                        router.settingsPath.append(.windowManager)
                    }
                }

                HaloGroupedRows {
                    HaloKeyValueRow(label: "Open windows", value: "\(windows.windows.count) of \(HaloWindowMetrics.maxWindows)")
                    HaloRowDivider()
                    HaloKeyValueRow(
                        label: "World tracking",
                        value: permissions.arSupported ? "Supported" : "Unavailable",
                        valueColor: permissions.arSupported ? HaloColor.success : HaloColor.warning
                    )
                    HaloRowDivider()
                    HaloKeyValueRow(
                        label: "LiDAR",
                        value: permissions.lidarSupported ? "Available" : "Not available",
                        valueColor: permissions.lidarSupported ? HaloColor.success : HaloColor.textSecondary
                    )
                }
            }

            HaloInfoNote(
                systemName: "info.circle",
                message: "On supported iPhones, HaloSpace uses ARKit world tracking and the rear camera so windows remain anchored as you move. In the Simulator, or without camera access, the workspace runs in an honest spatial preview mode.",
                accent: .ice
            )
        }
    }
}

// MARK: - Gestures

struct GesturesSettingsView: View {
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var permissions: PermissionManager

    private var simulatorNote: String? {
        #if targetEnvironment(simulator)
        return "Camera-based hand tracking is unavailable in the iOS Simulator. Test pinch gestures on a physical iPhone."
        #else
        return nil
        #endif
    }

    var body: some View {
        HaloSettingsPage(
            title: "Gestures & Controls",
            subtitle: "Tune touch and camera-based interaction for your spatial windows."
        ) {
            VStack(spacing: 9) {
                HaloSectionLabel(title: "Controls")
                HaloGroupedRows {
                    HaloToggleRow(
                        systemName: "hand.point.up.left",
                        title: "Spatial gestures",
                        subtitle: "Enable pinch selection and hand-driven window movement.",
                        accent: .amber,
                        isOn: $settings.gesturesEnabled
                    )
                    HaloRowDivider()
                    HaloToggleRow(
                        systemName: "camera.viewfinder",
                        title: "Camera hand tracking",
                        subtitle: "Use Vision hand-pose estimation on local camera frames.",
                        accent: .ice,
                        isOn: $settings.handTrackingEnabled
                    )
                    .disabled(!settings.gesturesEnabled)
                    .opacity(settings.gesturesEnabled ? 1 : 0.45)
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Recognition")
                HaloGroupedRows {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tracking rate")
                            .font(HaloFont.bodyMedium)
                            .foregroundStyle(HaloColor.textPrimary)
                        HaloSegmentedOptions(
                            options: HaloHandTrackingRate.allCases,
                            label: { $0.title },
                            selection: $settings.handTrackingRate
                        )
                        Text(settings.handTrackingRate.detail)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textTertiary)
                    }
                    .padding(.horizontal, HaloSpacing.md)
                    .padding(.vertical, 13)
                    .disabled(!settings.gesturesEnabled || !settings.handTrackingEnabled)
                    .opacity(settings.gesturesEnabled && settings.handTrackingEnabled ? 1 : 0.45)

                    HaloRowDivider()
                    HaloSliderRow(
                        title: "Pinch sensitivity",
                        subtitle: "How easily a pinch is recognized.",
                        valueLabel: "\(Int(settings.pinchSensitivity * 100))%",
                        value: $settings.pinchSensitivity,
                        range: 0.25...0.95,
                        step: 0.01
                    )
                    .disabled(!settings.gesturesEnabled)
                    .opacity(settings.gesturesEnabled ? 1 : 0.45)

                    HaloRowDivider()
                    HaloSliderRow(
                        title: "Drag sensitivity",
                        subtitle: "How far a window follows your hand.",
                        valueLabel: String(format: "%.1f×", settings.dragSensitivity),
                        value: $settings.dragSensitivity,
                        range: 0.4...1.8,
                        step: 0.1
                    )
                    .disabled(!settings.gesturesEnabled)
                    .opacity(settings.gesturesEnabled ? 1 : 0.45)
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Feedback")
                HaloGroupedRows {
                    HaloToggleRow(
                        systemName: "iphone.radiowaves.left.and.right",
                        title: "Haptic feedback",
                        subtitle: "Subtle taps when selecting, moving and closing windows.",
                        accent: .violet,
                        isOn: $settings.hapticsEnabled
                    )
                }
            }

            HaloGroupedRows {
                HaloKeyValueRow(label: "Gesture processing", value: "On-device")
                HaloRowDivider()
                HaloKeyValueRow(
                    label: "Camera permission",
                    value: permissions.camera.title,
                    valueColor: permissions.camera.isAuthorized ? HaloColor.success : HaloColor.warning
                )
                HaloRowDivider()
                HaloKeyValueRow(label: "Hand landmark model", value: "Apple Vision")
            }

            HaloInfoNote(
                systemName: "exclamationmark.triangle",
                message: "HaloSpace uses Apple Vision to estimate 2D hand landmarks from the rear camera and infers simple pinch gestures. This is not precision 3D hand tracking, and it is sensitive to lighting, distance and hand orientation."
            )

            if let simulatorNote {
                HaloInfoNote(systemName: "desktopcomputer", message: simulatorNote, accent: .amber)
            }
        }
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        HaloSettingsPage(
            title: "Appearance",
            subtitle: "Shape the glass surfaces of your spatial workspace."
        ) {
            WindowAppearancePreview(
                tint: settings.windowTint,
                transparency: settings.uiTransparency,
                showsLabels: settings.showWindowLabels
            )

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Window tint")
                HaloGroupedRows {
                    ForEach(Array(HaloWindowTint.allCases.enumerated()), id: \.offset) { index, tint in
                        if index > 0 { HaloRowDivider() }
                        Button {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            settings.windowTint = tint
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(tint.tintColor)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                                    )
                                Text(tint.title)
                                    .font(HaloFont.bodyMedium)
                                    .foregroundStyle(HaloColor.textPrimary)
                                Spacer()
                                Image(systemName: settings.windowTint == tint ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(settings.windowTint == tint ? HaloColor.ice : HaloColor.textTertiary)
                            }
                            .padding(.horizontal, HaloSpacing.md)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Glass")
                HaloGroupedRows {
                    HaloSliderRow(
                        title: "Surface opacity",
                        subtitle: "Controls how solid spatial window surfaces appear.",
                        valueLabel: "\(Int(settings.uiTransparency * 100))%",
                        value: $settings.uiTransparency,
                        range: 0.35...1.0,
                        step: 0.01
                    )
                    HaloRowDivider()
                    HaloToggleRow(
                        systemName: "textformat",
                        title: "Window labels",
                        subtitle: "Show application names in window title bars.",
                        accent: .silver,
                        isOn: $settings.showWindowLabels
                    )
                }
            }

            HaloInfoNote(
                systemName: "sparkles",
                message: "HaloSpace uses native materials and device rendering. Transparency can be reduced automatically by iOS accessibility settings."
            )
        }
    }
}

private struct WindowAppearancePreview: View {
    let tint: HaloWindowTint
    let transparency: Double
    let showsLabels: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                HaloIconTile(systemName: "note.text", accent: .amber, size: 22)
                if showsLabels {
                    Text("Halo Notes")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(HaloColor.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.white.opacity(0.13)).frame(width: 5, height: 5)
                    Circle().fill(Color.white.opacity(0.13)).frame(width: 5, height: 5)
                    Circle().fill(Color.white.opacity(0.13)).frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 34)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)

            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.22)).frame(width: 150, height: 6)
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.10)).frame(width: 208, height: 5)
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)).frame(width: 120, height: 5)
                Spacer()
                HStack(spacing: 5) {
                    Capsule().fill(HaloColor.ice.opacity(0.20)).frame(width: 48, height: 16)
                    Capsule().fill(Color.white.opacity(0.06)).frame(width: 32, height: 16)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 148)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.tintColor.opacity(0.55 + transparency * 0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.45), radius: 20, y: 10)
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Privacy

struct PrivacySecurityView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var permissions: PermissionManager

    @State private var pendingDeletion: PrivacyDeletion?
    @State private var isRequestingCamera = false

    private enum PrivacyDeletion: String, Identifiable {
        case workspace
        case notes
        case webApps
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .workspace: return "Delete saved workspace?"
            case .notes: return "Delete all notes?"
            case .webApps: return "Remove all web apps?"
            case .settings: return "Reset all settings?"
            }
        }

        var message: String {
            switch self {
            case .workspace: return "This closes every spatial window and removes the saved layout from this iPhone."
            case .notes: return "Your local notes will be permanently removed."
            case .webApps: return "Web app wrappers will be removed. This does not affect the websites themselves."
            case .settings: return "Spatial, gesture, appearance and developer preferences return to their defaults."
            }
        }
    }

    var body: some View {
        HaloSettingsPage(
            title: "Privacy & Security",
            subtitle: "HaloSpace processes spatial data on this device. Nothing is sent to a server."
        ) {
            VStack(spacing: 9) {
                HaloSectionLabel(title: "Camera")
                HaloGroupedRows {
                    HStack(spacing: 13) {
                        HaloIconTile(
                            systemName: permissions.camera.isAuthorized ? "camera.fill" : "camera",
                            accent: permissions.camera.isAuthorized ? .mint : .amber,
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Camera access")
                                .font(HaloFont.bodyMedium)
                                .foregroundStyle(HaloColor.textPrimary)
                            Text(permissions.camera.title)
                                .font(HaloFont.footnote)
                                .foregroundStyle(permissionColor)
                        }
                        Spacer()
                        Circle()
                            .fill(permissionColor)
                            .frame(width: 7, height: 7)
                    }
                    .padding(.horizontal, HaloSpacing.md)
                    .padding(.vertical, 13)

                    HaloRowDivider()

                    Text("HaloSpace uses the rear camera through ARKit to show your physical surroundings, and local Vision processing to estimate hand gestures. Camera frames are never recorded or uploaded.")
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, HaloSpacing.md)
                        .padding(.vertical, 12)

                    if permissions.camera == .notDetermined {
                        HaloRowDivider()
                        Button {
                            requestCamera()
                        } label: {
                            HStack(spacing: 8) {
                                if isRequestingCamera {
                                    ProgressView().tint(HaloColor.ice)
                                } else {
                                    Image(systemName: "camera.badge.ellipsis")
                                }
                                Text(isRequestingCamera ? "Requesting…" : "Allow Camera Access")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(HaloColor.textTertiary)
                            }
                            .font(HaloFont.bodyMedium)
                            .foregroundStyle(HaloColor.ice)
                            .padding(.horizontal, HaloSpacing.md)
                            .frame(height: 50)
                        }
                        .disabled(isRequestingCamera)
                    } else if permissions.camera == .denied || permissions.camera == .restricted {
                        HaloRowDivider()
                        Button {
                            permissions.openSystemSettings()
                        } label: {
                            HStack {
                                Text("Open iOS Settings")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .font(HaloFont.bodyMedium)
                            .foregroundStyle(HaloColor.ice)
                            .padding(.horizontal, HaloSpacing.md)
                            .frame(height: 50)
                        }
                    }
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Hand data")
                HaloGroupedRows {
                    HaloKeyValueRow(label: "Analysis", value: "On-device", valueColor: HaloColor.success)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Transmission", value: "None", valueColor: HaloColor.success)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Recording", value: "None", valueColor: HaloColor.success)
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Local data")
                HaloGroupedRows {
                    HaloKeyValueRow(label: "Spatial windows", value: "\(appState.windowManager.windows.count)")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Notes", value: "\(appState.notesStore.notes.count)")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Web apps", value: "\(appState.catalog.webApplications.count)")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Data location", value: "This iPhone")
                }

                HStack(spacing: 10) {
                    HaloActionTile(title: "Workspace", systemName: "trash", accent: .silver, isDestructive: true) {
                        pendingDeletion = .workspace
                    }
                    HaloActionTile(title: "Notes", systemName: "trash", accent: .silver, isDestructive: true) {
                        pendingDeletion = .notes
                    }
                    HaloActionTile(title: "Web Apps", systemName: "trash", accent: .silver, isDestructive: true) {
                        pendingDeletion = .webApps
                    }
                }
            }

            HaloGroupedRows {
                HaloNavigationRow(
                    systemName: "arrow.counterclockwise",
                    title: "Reset all settings",
                    subtitle: "Restore HaloSpace defaults",
                    accent: .amber
                ) {
                    pendingDeletion = .settings
                }
            }

            HaloInfoNote(
                systemName: "hand.raised",
                message: "HaloSpace does not include advertising, analytics or third-party tracking. Photos are accessed only through Apple's privacy-preserving picker. HaloSpace does not send notifications."
            )
        }
        .confirmationDialog(
            pendingDeletion?.title ?? "Delete data?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { item in
            Button("Delete", role: .destructive) { perform(item) }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { item in
            Text(item.message)
        }
        .onAppear { permissions.refresh() }
    }

    private var permissionColor: Color {
        switch permissions.camera {
        case .authorized: return HaloColor.success
        case .notDetermined: return HaloColor.warning
        case .denied, .restricted: return HaloColor.danger
        }
    }

    private func requestCamera() {
        isRequestingCamera = true
        Task {
            _ = await permissions.requestCameraAccess()
            isRequestingCamera = false
            HaloHaptics.impact(.light, enabled: settings.hapticsEnabled)
        }
    }

    private func perform(_ item: PrivacyDeletion) {
        switch item {
        case .workspace:
            appState.windowManager.closeAll()
            appState.windowManager.flushPersistence()
        case .notes:
            appState.notesStore.deleteAll()
        case .webApps:
            appState.catalog.deleteAllWebApplications()
        case .settings:
            settings.resetToDefaults()
        }
        pendingDeletion = nil
        HaloHaptics.success(enabled: settings.hapticsEnabled)
    }
}

// MARK: - Window Manager

struct WindowManagerSettingsView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windows: HaloWindowManager
    @EnvironmentObject private var catalog: ApplicationCatalog
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var permissions: PermissionManager

    @State private var showCloseAllConfirmation = false
    @State private var showResetConfirmation = false

    var body: some View {
        HaloSettingsPage(
            title: "Window Manager",
            subtitle: "Your workspace is restored relative to the space you enter next time."
        ) {
            summaryCard

            HStack(spacing: 10) {
                HaloActionTile(
                    title: "Tidy",
                    systemName: "rectangle.3.group",
                    accent: .violet,
                    isEnabled: !windows.visibleWindows.isEmpty
                ) {
                    windows.tidyWorkspace()
                }
                HaloActionTile(
                    title: "Save",
                    systemName: "internaldrive",
                    accent: .mint,
                    isEnabled: !windows.windows.isEmpty
                ) {
                    windows.flushPersistence()
                    HaloHaptics.success(enabled: settings.hapticsEnabled)
                }
                HaloActionTile(
                    title: "Close All",
                    systemName: "xmark.rectangle",
                    accent: .silver,
                    isDestructive: true,
                    isEnabled: !windows.windows.isEmpty
                ) {
                    showCloseAllConfirmation = true
                }
                HaloActionTile(title: "Reset", systemName: "arrow.counterclockwise", accent: .amber) {
                    showResetConfirmation = true
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Open windows", trailing: "\(windows.windows.count)/\(HaloWindowMetrics.maxWindows)")

                if windows.windows.isEmpty {
                    HaloGroupedRows {
                        HaloEmptyState(
                            systemName: "rectangle.on.rectangle.slash",
                            title: "No windows open",
                            message: "Open an application to create your first spatial window."
                        )
                        HaloRowDivider()
                        Button {
                            router.selectedTab = .apps
                        } label: {
                            HStack {
                                Text("Browse Applications")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .font(HaloFont.bodyMedium)
                            .foregroundStyle(HaloColor.ice)
                            .padding(.horizontal, HaloSpacing.md)
                            .frame(height: 50)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(windows.windows.sorted { $0.zIndex > $1.zIndex }) { window in
                            windowRow(window)
                        }
                    }
                }
            }

            HaloGroupedRows {
                HaloKeyValueRow(label: "Placement", value: settings.windowPlacement.title)
                HaloRowDivider()
                HaloKeyValueRow(label: "Window scale", value: "\(Int(settings.windowScale * 100))%")
                HaloRowDivider()
                HaloKeyValueRow(label: "World tracking", value: permissions.arSupported ? "Available" : "Preview only")
                HaloRowDivider()
                HaloKeyValueRow(label: "Storage", value: "Local JSON · Documents")
            }

            HaloInfoNote(
                systemName: "viewfinder",
                message: "Spatial positions are saved relative to your workspace anchor rather than absolute world coordinates. If tracking changes, HaloSpace restores windows in front of you instead of using stale positions."
            )
        }
        .confirmationDialog(
            "Close all windows?",
            isPresented: $showCloseAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Close All", role: .destructive) {
                windows.closeAll()
                HaloHaptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every open spatial window will be closed.")
        }
        .confirmationDialog(
            "Reset workspace?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Workspace", role: .destructive) {
                windows.resetWorkspace()
                HaloHaptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("HaloSpace recreates the starter workspace. Your custom layout will be replaced.")
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(HaloColor.ice.opacity(0.10))
                    .frame(width: 48, height: 48)
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(HaloColor.ice)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(windows.windows.isEmpty ? "Workspace is empty" : "\(windows.windows.count) window\(windows.windows.count == 1 ? "" : "s") in workspace")
                    .font(HaloFont.headline)
                    .foregroundStyle(HaloColor.textPrimary)
                if let focused = windows.focusedWindow {
                    Text("Focused: \(focused.title)")
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Saved on this iPhone")
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                }
            }
            Spacer()
            HaloStatusDot(color: windows.windows.isEmpty ? HaloColor.textTertiary : HaloColor.success)
        }
        .padding(14)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                tint: Color.white.opacity(0.03),
                strokeOpacity: 0.11,
                shadowRadius: 14
            )
        )
    }

    private func windowRow(_ window: HaloWindowModel) -> some View {
        let descriptor = catalog.descriptor(for: window.applicationID)
        let isFocused = windows.focusedWindowID == window.id
        return HStack(spacing: 11) {
            HaloIconTile(
                systemName: descriptor?.iconSystemName ?? "app",
                accent: descriptor?.accent ?? .ice,
                size: 34
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(window.title)
                    .font(HaloFont.subheadline)
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(descriptor?.name ?? "Application")
                    Text("·")
                    Text(window.isMinimized ? "Minimized" : isFocused ? "Focused" : "Open")
                        .foregroundStyle(isFocused ? HaloColor.ice : HaloColor.textTertiary)
                }
                .font(.system(size: 10.5))
                .foregroundStyle(HaloColor.textTertiary)
            }
            Spacer(minLength: 4)
            HaloIconButton(
                systemName: window.isMinimized ? "arrow.up.left.and.arrow.down.right" : "minus",
                accessibilityLabel: window.isMinimized ? "Restore \(window.title)" : "Minimize \(window.title)",
                size: 30
            ) {
                windows.toggleMinimized(window.id)
            }
            HaloIconButton(
                systemName: "xmark",
                accessibilityLabel: "Close \(window.title)",
                size: 30
            ) {
                windows.close(window.id)
            }
        }
        .padding(11)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                tint: isFocused ? HaloColor.ice.opacity(0.055) : Color.white.opacity(0.022),
                strokeOpacity: isFocused ? 0.22 : 0.08,
                shadowRadius: 10
            )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            windows.focus(window.id)
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
        }
    }
}
