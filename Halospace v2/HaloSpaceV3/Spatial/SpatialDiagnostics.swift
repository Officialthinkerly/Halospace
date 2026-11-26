//
//  SpatialDiagnostics.swift
//  HaloSpace V3
//

import Foundation
import UIKit

struct SpatialDiagnosticsSnapshot {
    var sessionState: String = "Idle"
    var trackingState: String = "Not started"
    var mode: String = "None"
    var cameraFPS: Double = 0
    var renderFPS: Double = 0
    var handTrackingState: String = "Idle"
    var handTrackingFPS: Double = 0
    var windowCount: Int = 0
    var entityCount: Int = 0
    var lastError: String?
    var lastUpdated: Date = Date()

    static let empty = SpatialDiagnosticsSnapshot()

    var isActive: Bool {
        sessionState != "Idle" && sessionState != "Stopped"
    }
}

@MainActor
final class SpatialDiagnosticsCenter: ObservableObject {
    static let shared = SpatialDiagnosticsCenter()

    @Published private(set) var snapshot: SpatialDiagnosticsSnapshot = .empty

    private init() {}

    func update(_ mutation: (inout SpatialDiagnosticsSnapshot) -> Void) {
        var copy = snapshot
        mutation(&copy)
        copy.lastUpdated = Date()
        snapshot = copy
    }

    func reset() {
        snapshot = .empty
    }

    func makeReport(deviceSummary: String) -> String {
        let s = snapshot
        return """
        HaloSpace Diagnostics
        Device: \(deviceSummary)
        Session: \(s.sessionState)
        Mode: \(s.mode)
        Tracking: \(s.trackingState)
        Camera FPS: \(String(format: "%.1f", s.cameraFPS))
        Display FPS: \(String(format: "%.1f", s.renderFPS))
        Hand tracking: \(s.handTrackingState) (\(String(format: "%.1f", s.handTrackingFPS)) FPS)
        Windows: \(s.windowCount)
        Entities: \(s.entityCount)
        Last error: \(s.lastError ?? "None")
        Updated: \(s.lastUpdated.formatted(date: .abbreviated, time: .standard))
        """
    }
}

enum HaloDeviceInfo {
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
    }

    static var summary: String {
        let device = UIDevice.current
        return "\(device.name) · \(modelIdentifier) · \(device.systemName) \(device.systemVersion)"
    }
}
