//
//  SpatialWorkspaceRoot.swift
//  HaloSpace V3
//

import SwiftUI

struct SpatialWorkspaceRoot: View {
    let launchMode: HaloLaunchMode
    let onExit: () -> Void

    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windowManager: HaloWindowManager
    @EnvironmentObject private var permissions: PermissionManager
    @ObservedObject private var diagnostics = SpatialDiagnosticsCenter.shared

    @StateObject private var sessionManager = SpatialSessionManager()
    @StateObject private var handProcessor = VisionHandPoseProcessor()

    @State private var permissionChecked = false
    @State private var cameraAuthorized = false
    @State private var pinchedWindowID: UUID?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if permissionChecked && cameraAuthorized {
                    SpatialARContainerView(
                        sessionManager: sessionManager,
                        settings: settings,
                        windowManager: windowManager,
                        launchMode: launchMode,
                        handProcessor: handProcessor
                    )
                    .ignoresSafeArea()
                    .onTapGesture { location in
                        handleBackgroundTap(at: location)
                    }

                    windowsLayer(viewportSize: proxy.size)

                    handCursorOverlay
                } else if permissionChecked && !cameraAuthorized {
                    HaloAmbientBackground(mood: .workspace)
                    permissionDeniedView
                } else {
                    HaloAmbientBackground(mood: .workspace)
                    preparingView
                }

                hudOverlay
            }
            .onAppear {
                sessionManager.updateViewportSize(proxy.size)
                prepareSpatialEnvironment()
            }
            .onChange(of: proxy.size) { newSize in
                sessionManager.updateViewportSize(newSize)
            }
            .onChange(of: windowManager.windows) { windows in
                sessionManager.syncWindows(windows)
            }
            .onDisappear {
                sessionManager.stopSession()
                handProcessor.reset()
                HaloLog.info("Spatial workspace dismissed (mode: \(launchMode.rawValue))")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Windows Layer

    private func windowsLayer(viewportSize: CGSize) -> some View {
        ZStack {
            ForEach(windowManager.visibleWindows) { window in
                let projection = sessionManager.projectedFrames[window.id]
                    ?? ProjectedWindowFrame(
                        screenCenter: CGPoint(x: viewportSize.width * 0.5, y: viewportSize.height * 0.45),
                        scale: 1.0,
                        isInFront: true,
                        distance: 1.45
                    )

                if projection.isInFront {
                    SpatialWindowContainer(
                        window: window,
                        isFocused: windowManager.focusedWindowID == window.id,
                        projectedScale: projection.scale,
                        onFocus: {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            windowManager.focus(window.id)
                        },
                        onClose: {
                            HaloHaptics.impact(.light, enabled: settings.hapticsEnabled)
                            windowManager.close(window.id)
                        },
                        onMinimize: {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            windowManager.minimize(window.id)
                        },
                        onMoveDelta: { translation in
                            moveWindow(window.id, screenDelta: translation, distance: projection.distance)
                        },
                        onResize: { newSize in
                            windowManager.resize(window.id, to: newSize)
                        }
                    )
                    .position(projection.screenCenter)
                    .zIndex(Double(window.zIndex))
                }
            }
        }
    }

    // MARK: - Hand Tracking Cursor

    @ViewBuilder
    private var handCursorOverlay: some View {
        if settings.handTrackingEnabled, settings.gesturesEnabled, let point = handProcessor.cursorPoint {
            ZStack {
                Circle()
                    .fill(handProcessor.isPinching ? HaloColor.ice.opacity(0.35) : Color.white.opacity(0.16))
                    .frame(width: handProcessor.isPinching ? 20 : 28, height: handProcessor.isPinching ? 20 : 28)
                Circle()
                    .strokeBorder(handProcessor.isPinching ? HaloColor.ice : Color.white.opacity(0.85), lineWidth: 1.8)
                    .frame(width: handProcessor.isPinching ? 20 : 28, height: handProcessor.isPinching ? 20 : 28)
            }
            .position(point)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.08), value: handProcessor.isPinching)
        }
    }

    // MARK: - HUD & Dock

    private var hudOverlay: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HaloIconButton(systemName: "xmark", accessibilityLabel: "Exit HaloSpace", size: 40) {
                    HaloHaptics.impact(.light, enabled: settings.hapticsEnabled)
                    onExit()
                }

                Spacer()

                if let message = sessionManager.trackingBanner.message {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(HaloColor.warning)
                            .frame(width: 6, height: 6)
                        Text(message)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(HaloColor.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7))
                    )
                }

                Spacer()

                if launchMode == .ultraFast {
                    Text("Ultra Fast")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(HaloColor.ice)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if settings.showDiagnosticsOverlay {
                diagnosticsHUD
                    .padding(.horizontal, 16)
            }

            if let error = windowManager.lastErrorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HaloColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.75)))
                    .onTapGesture { windowManager.clearError() }
            }

            Spacer()

            if permissionChecked && cameraAuthorized {
                SpatialDock(
                    onRecenter: { sessionManager.recenterWorkspace() },
                    onTidy: {
                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                        windowManager.tidyWorkspace()
                    }
                )
                .padding(.bottom, 10)
            }
        }
    }

    private var diagnosticsHUD: some View {
        let s = diagnostics.snapshot
        return HStack(spacing: 12) {
            Text("\(s.mode) · \(s.trackingState)")
            Text("Cam \(String(format: "%.0f", s.cameraFPS))fps")
            Text("UI \(String(format: "%.0f", s.renderFPS))fps")
            Text("Hand \(s.handTrackingState)")
            Text("Win \(s.windowCount)")
        }
        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
        .foregroundStyle(HaloColor.ice)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.65)))
    }

    private var preparingView: some View {
        VStack(spacing: 16) {
            HaloLogoMark(size: 72, animated: true)
            Text("Preparing your space")
                .font(HaloFont.title2)
                .foregroundStyle(HaloColor.textPrimary)
            Text("Checking camera and spatial sensors…")
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textSecondary)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 36))
                .foregroundStyle(HaloColor.warning)
            Text("Camera Access Required")
                .font(HaloFont.title2)
                .foregroundStyle(HaloColor.textPrimary)
            Text("HaloSpace uses the rear camera for real-time passthrough, world tracking, and on-device hand gestures.")
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            HaloPrimaryButton(title: "Open Settings", systemImage: "gearshape") {
                permissions.openSystemSettings()
            }
            .padding(.horizontal, 36)
        }
    }

    // MARK: - Setup & Interactions

    private func prepareSpatialEnvironment() {
        windowManager.prepareForSpatialEntry()
        wireHandGestures()

        Task {
            let granted = await permissions.requestCameraAccess()
            cameraAuthorized = granted
            permissionChecked = true
            if granted {
                sessionManager.syncWindows(windowManager.windows)
            }
        }
    }

    private func wireHandGestures() {
        handProcessor.onPinchBegan = { point in
            if let hitID = hitTestWindow(at: point) {
                pinchedWindowID = hitID
                windowManager.focus(hitID)
                HaloHaptics.selection(enabled: settings.hapticsEnabled)
            } else {
                pinchedWindowID = nil
            }
        }
        handProcessor.onPinchMoved = { _, delta in
            guard let id = pinchedWindowID else { return }
            let sensitivity = CGFloat(0.6 + settings.dragSensitivity * 0.9)
            let scaled = CGSize(width: delta.width * sensitivity, height: delta.height * sensitivity)
            let dist = sessionManager.projectedFrames[id]?.distance ?? 1.45
            moveWindow(id, screenDelta: scaled, distance: dist)
        }
        handProcessor.onPinchEnded = { _ in
            pinchedWindowID = nil
        }
    }

    private func hitTestWindow(at point: CGPoint) -> UUID? {
        for window in windowManager.visibleWindows.reversed() {
            guard let frame = sessionManager.projectedFrames[window.id], frame.isInFront else { continue }
            let scale = frame.scale * CGFloat(settings.windowScale)
            let w = window.logicalSize.width * scale
            let h = window.logicalSize.height * scale
            let rect = CGRect(x: frame.screenCenter.x - w * 0.5, y: frame.screenCenter.y - h * 0.5, width: w, height: h)
            if rect.contains(point) {
                return window.id
            }
        }
        return nil
    }

    private func moveWindow(_ id: UUID, screenDelta: CGSize, distance: Float) {
        let metersPerPoint: Float = max(0.0014, 0.0018 * (distance / 1.45))
        let dx = Float(screenDelta.width) * metersPerPoint
        let dy = -Float(screenDelta.height) * metersPerPoint
        windowManager.move(id, localDelta: SIMD3<Float>(dx, dy, 0))
    }

    private func handleBackgroundTap(at location: CGPoint) {
        if let focusedID = windowManager.focusedWindowID,
           let placement = sessionManager.raycastWorldPosition(at: location) {
            windowManager.setPosition(focusedID, position: HaloVector3(placement))
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
        } else {
            windowManager.unfocus()
        }
    }
}
