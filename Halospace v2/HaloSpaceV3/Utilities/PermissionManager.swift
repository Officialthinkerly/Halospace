//
//  PermissionManager.swift
//  HaloSpace V3
//

import AVFoundation
import ARKit
import SwiftUI
import UIKit

enum HaloCameraPermission: String {
    case notDetermined
    case authorized
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: return "Not requested"
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        }
    }

    var isAuthorized: Bool { self == .authorized }
}

@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published private(set) var camera: HaloCameraPermission = .notDetermined

    private init() {
        refresh()
    }

    var arSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }

    var lidarSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    func refresh() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            camera = .authorized
        case .denied:
            camera = .denied
        case .restricted:
            camera = .restricted
        case .notDetermined:
            camera = .notDetermined
        @unknown default:
            camera = .notDetermined
        }
    }

    func requestCameraAccess() async -> Bool {
        refresh()
        if camera == .authorized { return true }
        guard camera == .notDetermined else { return false }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        refresh()
        return granted
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    var statusSummary: String {
        if !arSupported { return "Spatial preview available" }
        switch camera {
        case .authorized: return "Spatial engine ready"
        case .notDetermined: return "Camera access needed"
        case .denied, .restricted: return "Camera access unavailable"
        }
    }
}
