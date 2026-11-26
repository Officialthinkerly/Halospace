//
//  SpatialSessionManager.swift
//  HaloSpace V3
//

import ARKit
import Combine
import RealityKit
import SwiftUI

struct ProjectedWindowFrame: Equatable {
    let screenCenter: CGPoint
    let scale: CGFloat
    let isInFront: Bool
    let distance: Float
}

enum SpatialTrackingBanner: Equatable {
    case normal
    case initializing
    case limited(String)
    case interrupted
    case unavailable(String)
    case failed(String)

    var message: String? {
        switch self {
        case .normal: return nil
        case .initializing: return "Initializing spatial tracking…"
        case .limited(let reason): return reason
        case .interrupted: return "Tracking interrupted — hold steady"
        case .unavailable(let msg): return msg
        case .failed(let msg): return msg
        }
    }

    var isWarning: Bool {
        switch self {
        case .normal: return false
        default: return true
        }
    }
}

@MainActor
final class SpatialSessionManager: NSObject, ObservableObject {
    @Published private(set) var projectedFrames: [UUID: ProjectedWindowFrame] = [:]
    @Published private(set) var trackingBanner: SpatialTrackingBanner = .initializing
    @Published private(set) var isSessionRunning = false
    @Published private(set) var viewportSize: CGSize = UIScreen.main.bounds.size

    weak var arView: ARView?
    private var workspaceAnchor: AnchorEntity?
    private var windowEntities: [UUID: ModelEntity] = [:]
    private var displayLink: CADisplayLink?

    private var settings: HaloSettingsModel?
    private var windowManager: HaloWindowManager?
    private var launchMode: HaloLaunchMode = .ar
    private var handProcessor: VisionHandPoseProcessor?

    private var frameCount = 0
    private var lastFPSCheck = CACurrentMediaTime()
    private var renderFrameCount = 0
    private var lastRenderFPSCheck = CACurrentMediaTime()
    private var needsInitialPlacement = true

    func configure(
        arView: ARView,
        settings: HaloSettingsModel,
        windowManager: HaloWindowManager,
        launchMode: HaloLaunchMode,
        handProcessor: VisionHandPoseProcessor
    ) {
        self.arView = arView
        self.settings = settings
        self.windowManager = windowManager
        self.launchMode = launchMode
        self.handProcessor = handProcessor

        arView.session.delegate = self
        arView.renderOptions.insert(.disableMotionBlur)
        if launchMode == .ultraFast || settings.performanceMode {
            arView.renderOptions.insert(.disableDepthOfField)
            arView.renderOptions.insert(.disableHDR)
        }

        startSession()
        startProjectionLoop()
    }

    func updateViewportSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        viewportSize = size
    }

    func startSession() {
        guard let arView else { return }
        guard ARWorldTrackingConfiguration.isSupported else {
            trackingBanner = .unavailable("ARKit world tracking is unavailable on this device")
            SpatialDiagnosticsCenter.shared.update {
                $0.sessionState = "Unavailable"
                $0.trackingState = "Unsupported"
                $0.mode = launchMode.compactTitle
            }
            return
        }

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        if let settings, settings.planeDetectionEnabled && launchMode != .ultraFast {
            config.planeDetection = [.horizontal, .vertical]
        } else {
            config.planeDetection = []
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) && launchMode != .ultraFast {
            config.frameSemantics = []
        }

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isSessionRunning = true
        needsInitialPlacement = true
        trackingBanner = .initializing

        SpatialDiagnosticsCenter.shared.update {
            $0.sessionState = "Running"
            $0.mode = launchMode.compactTitle
            $0.trackingState = "Initializing"
        }
    }

    func stopSession() {
        displayLink?.invalidate()
        displayLink = nil
        arView?.session.pause()
        isSessionRunning = false
        windowEntities.values.forEach { $0.removeFromParent() }
        windowEntities.removeAll()
        workspaceAnchor?.removeFromParent()
        workspaceAnchor = nil
        SpatialDiagnosticsCenter.shared.reset()
    }

    func recenterWorkspace() {
        guard let arView, let frame = arView.session.currentFrame else { return }
        placeWorkspaceAnchor(inFrontOf: frame.camera.transform, in: arView)
        if let settings {
            HaloHaptics.impact(.light, enabled: settings.hapticsEnabled)
        }
    }

    func syncWindows(_ windows: [HaloWindowModel]) {
        guard let arView else { return }
        if workspaceAnchor == nil, let frame = arView.session.currentFrame {
            placeWorkspaceAnchor(inFrontOf: frame.camera.transform, in: arView)
        }
        guard let anchor = workspaceAnchor else { return }

        let activeIDs = Set(windows.filter { !$0.isMinimized }.map(\.id))

        for (id, entity) in windowEntities where !activeIDs.contains(id) {
            entity.removeFromParent()
            windowEntities.removeValue(forKey: id)
        }

        for window in windows where !window.isMinimized {
            let width = HaloWindowMetrics.physicalWidth(for: window.logicalSize)
            let height = HaloWindowMetrics.physicalHeight(for: window.logicalSize)
            let entity: ModelEntity
            if let existing = windowEntities[window.id] {
                entity = existing
            } else {
                let mesh = MeshResource.generatePlane(width: width, height: height, cornerRadius: 0.04)
                var material = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.015))
                material.blending = .transparent(opacity: .init(floatLiteral: 0.02))
                entity = ModelEntity(mesh: mesh, materials: [material])
                entity.name = "window.\(window.id.uuidString)"
                anchor.addChild(entity)
                windowEntities[window.id] = entity
            }

            entity.position = window.localPosition.simdValue
            entity.orientation = simd_quatf(angle: window.localYaw, axis: SIMD3<Float>(0, 1, 0))
            let scale = Float(settings?.windowScale ?? 1.0)
            entity.scale = SIMD3<Float>(repeating: scale)
        }

        SpatialDiagnosticsCenter.shared.update {
            $0.windowCount = activeIDs.count
            $0.entityCount = windowEntities.count
        }
    }

    func raycastWorldPosition(at screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let arView, let anchor = workspaceAnchor else { return nil }
        let results = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .any)
        guard let hit = results.first else { return nil }
        let worldPos = SIMD3<Float>(hit.worldTransform.columns.3.x, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
        let localPos = anchor.convert(position: worldPos, from: nil)
        return SIMD3<Float>(
            min(max(localPos.x, HaloWindowMetrics.horizontalRange.lowerBound), HaloWindowMetrics.horizontalRange.upperBound),
            min(max(localPos.y, HaloWindowMetrics.verticalRange.lowerBound), HaloWindowMetrics.verticalRange.upperBound),
            min(max(localPos.z, HaloWindowMetrics.depthRange.lowerBound), HaloWindowMetrics.depthRange.upperBound)
        )
    }

    private func placeWorkspaceAnchor(inFrontOf cameraTransform: simd_float4x4, in arView: ARView) {
        workspaceAnchor?.removeFromParent()
        windowEntities.values.forEach { $0.removeFromParent() }
        windowEntities.removeAll()

        let forward = SIMD3<Float>(-cameraTransform.columns.2.x, 0, -cameraTransform.columns.2.z)
        let horizontalForward = simd_length(forward) > 0.001 ? simd_normalize(forward) : SIMD3<Float>(0, 0, -1)
        let cameraPos = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        let anchorPos = cameraPos + horizontalForward * 1.45

        let yaw = atan2(-horizontalForward.x, -horizontalForward.z)
        var anchorTransform = matrix_identity_float4x4
        let rotation = simd_float4x4(simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0)))
        anchorTransform = rotation
        anchorTransform.columns.3 = SIMD4<Float>(anchorPos.x, anchorPos.y, anchorPos.z, 1)

        let anchor = AnchorEntity(world: anchorTransform)
        arView.scene.addAnchor(anchor)
        workspaceAnchor = anchor
        needsInitialPlacement = false

        if let windowManager {
            syncWindows(windowManager.windows)
        }
    }

    private func startProjectionLoop() {
        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayTick))
        link.preferredFrameRateRange = launchMode == .ultraFast
            ? CAFrameRateRange(minimum: 24, maximum: 30, preferred: 30)
            : CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func handleDisplayTick() {
        renderFrameCount += 1
        let now = CACurrentMediaTime()
        if now - lastRenderFPSCheck >= 1.0 {
            let fps = Double(renderFrameCount) / (now - lastRenderFPSCheck)
            renderFrameCount = 0
            lastRenderFPSCheck = now
            SpatialDiagnosticsCenter.shared.update { $0.renderFPS = fps }
        }

        updateProjectedFrames()
    }

    private func updateProjectedFrames() {
        guard let windowManager else { return }
        let visible = windowManager.visibleWindows
        guard let arView, let anchor = workspaceAnchor, ARWorldTrackingConfiguration.isSupported else {
            // Fallback projection when ARKit isn't active (e.g. simulator or pre-tracking)
            var fallback: [UUID: ProjectedWindowFrame] = [:]
            let w = viewportSize.width
            let h = viewportSize.height
            for window in visible {
                let x = w * 0.5 + CGFloat(window.localPosition.x) * 240
                let y = h * 0.45 - CGFloat(window.localPosition.y) * 240
                let depthScale = CGFloat(max(0.65, min(1.25, 1.0 - window.localPosition.z * 0.35)))
                fallback[window.id] = ProjectedWindowFrame(
                    screenCenter: CGPoint(x: x, y: y),
                    scale: depthScale,
                    isInFront: true,
                    distance: window.estimatedDistanceFromAnchor
                )
            }
            projectedFrames = fallback
            return
        }

        let cameraTransform = arView.cameraTransform
        let cameraPos = cameraTransform.translation
        let cameraForward = -SIMD3<Float>(
            cameraTransform.matrix.columns.2.x,
            cameraTransform.matrix.columns.2.y,
            cameraTransform.matrix.columns.2.z
        )

        var nextFrames: [UUID: ProjectedWindowFrame] = [:]
        for window in visible {
            let worldPos: SIMD3<Float>
            if let entity = windowEntities[window.id] {
                worldPos = entity.position(relativeTo: nil)
            } else {
                worldPos = anchor.convert(position: window.localPosition.simdValue, to: nil)
            }

            let toWindow = worldPos - cameraPos
            let distance = simd_length(toWindow)
            let isInFront = simd_dot(toWindow, cameraForward) > 0.15

            if isInFront, let projected = arView.project(worldPos) {
                let clampedDistance = max(0.75, min(3.2, distance))
                let depthScale = CGFloat(1.45 / clampedDistance)
                nextFrames[window.id] = ProjectedWindowFrame(
                    screenCenter: projected,
                    scale: min(max(depthScale, 0.52), 1.35),
                    isInFront: true,
                    distance: distance
                )
            } else {
                nextFrames[window.id] = ProjectedWindowFrame(
                    screenCenter: CGPoint(x: -2000, y: -2000),
                    scale: 0.7,
                    isInFront: false,
                    distance: distance
                )
            }
        }
        projectedFrames = nextFrames
    }
}

extension SpatialSessionManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        let cameraTransform = frame.camera.transform
        let trackingState = frame.camera.trackingState

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.frameCount += 1
            let now = CACurrentMediaTime()
            if now - self.lastFPSCheck >= 1.0 {
                let fps = Double(self.frameCount) / (now - self.lastFPSCheck)
                self.frameCount = 0
                self.lastFPSCheck = now
                SpatialDiagnosticsCenter.shared.update { $0.cameraFPS = fps }
            }

            if self.needsInitialPlacement, case .normal = trackingState, let arView = self.arView {
                self.placeWorkspaceAnchor(inFrontOf: cameraTransform, in: arView)
            }

            self.updateTrackingState(trackingState)

            if let settings = self.settings,
               settings.handTrackingEnabled && settings.gesturesEnabled {
                self.handProcessor?.process(
                    pixelBuffer: pixelBuffer,
                    viewportSize: self.viewportSize,
                    rate: settings.handTrackingRate,
                    pinchSensitivity: settings.pinchSensitivity
                )
            }
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.trackingBanner = .failed("AR session error: \(error.localizedDescription)")
            SpatialDiagnosticsCenter.shared.update {
                $0.sessionState = "Failed"
                $0.lastError = error.localizedDescription
            }
        }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor [weak self] in
            self?.trackingBanner = .interrupted
            SpatialDiagnosticsCenter.shared.update {
                $0.sessionState = "Interrupted"
                $0.trackingState = "Interrupted"
            }
        }
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor [weak self] in
            self?.trackingBanner = .initializing
            SpatialDiagnosticsCenter.shared.update {
                $0.sessionState = "Running"
                $0.trackingState = "Recovering"
            }
        }
    }

    private func updateTrackingState(_ state: ARCamera.TrackingState) {
        let label: String
        switch state {
        case .normal:
            trackingBanner = .normal
            label = "Normal"
        case .notAvailable:
            trackingBanner = .initializing
            label = "Not available"
        case .limited(let reason):
            switch reason {
            case .initializing:
                trackingBanner = .initializing
                label = "Initializing"
            case .excessiveMotion:
                trackingBanner = .limited("Slow down device movement")
                label = "Excessive motion"
            case .insufficientFeatures:
                trackingBanner = .limited("Point at a well-lit surface")
                label = "Insufficient features"
            case .relocalizing:
                trackingBanner = .limited("Relocalizing space…")
                label = "Relocalizing"
            @unknown default:
                trackingBanner = .limited("Limited tracking")
                label = "Limited"
            }
        }
        SpatialDiagnosticsCenter.shared.update { $0.trackingState = label }
    }
}

struct SpatialARContainerView: UIViewRepresentable {
    let sessionManager: SpatialSessionManager
    let settings: HaloSettingsModel
    let windowManager: HaloWindowManager
    let launchMode: HaloLaunchMode
    let handProcessor: VisionHandPoseProcessor

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        view.backgroundColor = .black
        sessionManager.configure(
            arView: view,
            settings: settings,
            windowManager: windowManager,
            launchMode: launchMode,
            handProcessor: handProcessor
        )
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        sessionManager.updateViewportSize(uiView.bounds.size)
    }
}
