//
//  VisionHandPoseProcessor.swift
//  HaloSpace V3
//

import CoreVideo
import Foundation
import SwiftUI
import Vision

private final class HandPoseWorkerState: @unchecked Sendable {
    var isProcessing = false
    var frameCount = 0
    var lastFPSCheck: CFTimeInterval = CACurrentMediaTime()
}

@MainActor
final class VisionHandPoseProcessor: ObservableObject {
    @Published private(set) var cursorPoint: CGPoint?
    @Published private(set) var isPinching = false
    @Published private(set) var handDetected = false

    var onPinchBegan: ((CGPoint) -> Void)?
    var onPinchMoved: ((CGPoint, CGSize) -> Void)?
    var onPinchEnded: ((CGPoint) -> Void)?

    private let processingQueue = DispatchQueue(label: "com.halospace.vision.handpose", qos: .userInitiated)
    private let workerState = HandPoseWorkerState()
    private var lastProcessedTime: CFTimeInterval = 0

    private var smoothedPoint: CGPoint?
    private var lastPinchPoint: CGPoint?
    private var wasPinching = false

    func reset() {
        cursorPoint = nil
        isPinching = false
        handDetected = false
        smoothedPoint = nil
        lastPinchPoint = nil
        wasPinching = false
        SpatialDiagnosticsCenter.shared.update {
            $0.handTrackingState = "Idle"
            $0.handTrackingFPS = 0
        }
    }

    func process(
        pixelBuffer: CVPixelBuffer,
        viewportSize: CGSize,
        rate: HaloHandTrackingRate,
        pinchSensitivity: Double
    ) {
        let now = CACurrentMediaTime()
        let minInterval = 1.0 / max(1.0, rate.framesPerSecond)
        guard !workerState.isProcessing, (now - lastProcessedTime) >= minInterval else { return }
        workerState.isProcessing = true
        lastProcessedTime = now

        let state = workerState
        processingQueue.async { [weak self] in
            defer { state.isProcessing = false }
            guard let self else { return }

            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return
            }

            state.frameCount += 1
            let checkNow = CACurrentMediaTime()
            let measuredFPS: Double?
            if checkNow - state.lastFPSCheck >= 1.0 {
                measuredFPS = Double(state.frameCount) / (checkNow - state.lastFPSCheck)
                state.frameCount = 0
                state.lastFPSCheck = checkNow
            } else {
                measuredFPS = nil
            }

            guard let observation = request.results?.first,
                  let thumbTip = try? observation.recognizedPoint(.thumbTip),
                  let indexTip = try? observation.recognizedPoint(.indexTip),
                  thumbTip.confidence > 0.35,
                  indexTip.confidence > 0.35 else {
                Task { @MainActor in
                    self.handleNoHand(fps: measuredFPS)
                }
                return
            }

            // Vision normalized coordinates have origin at bottom-left; convert to SwiftUI top-left
            let midpointNorm = CGPoint(
                x: (thumbTip.location.x + indexTip.location.x) * 0.5,
                y: 1.0 - (thumbTip.location.y + indexTip.location.y) * 0.5
            )
            let screenPoint = CGPoint(
                x: midpointNorm.x * viewportSize.width,
                y: midpointNorm.y * viewportSize.height
            )
            let distance = hypot(thumbTip.location.x - indexTip.location.x, thumbTip.location.y - indexTip.location.y)
            let threshold = 0.045 + (1.0 - pinchSensitivity) * 0.035
            let pinching = distance < threshold

            Task { @MainActor in
                self.handleHandUpdate(point: screenPoint, pinching: pinching, fps: measuredFPS)
            }
        }
    }

    private func handleNoHand(fps: Double?) {
        if wasPinching, let last = lastPinchPoint {
            onPinchEnded?(last)
        }
        wasPinching = false
        lastPinchPoint = nil
        isPinching = false
        handDetected = false
        cursorPoint = nil
        smoothedPoint = nil

        SpatialDiagnosticsCenter.shared.update {
            $0.handTrackingState = "Searching"
            if let fps { $0.handTrackingFPS = fps }
        }
    }

    private func handleHandUpdate(point: CGPoint, pinching: Bool, fps: Double?) {
        let alpha: CGFloat = 0.38
        let filtered: CGPoint
        if let prev = smoothedPoint {
            filtered = CGPoint(
                x: prev.x + (point.x - prev.x) * alpha,
                y: prev.y + (point.y - prev.y) * alpha
            )
        } else {
            filtered = point
        }
        smoothedPoint = filtered
        cursorPoint = filtered
        handDetected = true
        isPinching = pinching

        if pinching && !wasPinching {
            lastPinchPoint = filtered
            onPinchBegan?(filtered)
        } else if pinching && wasPinching {
            let prev = lastPinchPoint ?? filtered
            let delta = CGSize(width: filtered.x - prev.x, height: filtered.y - prev.y)
            lastPinchPoint = filtered
            onPinchMoved?(filtered, delta)
        } else if !pinching && wasPinching {
            onPinchEnded?(filtered)
            lastPinchPoint = nil
        }
        wasPinching = pinching

        SpatialDiagnosticsCenter.shared.update {
            $0.handTrackingState = pinching ? "Pinching" : "Tracking"
            if let fps { $0.handTrackingFPS = fps }
        }
    }
}
