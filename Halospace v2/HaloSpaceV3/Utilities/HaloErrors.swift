//
//  HaloErrors.swift
//  HaloSpace V3
//

import Foundation

enum HaloSpatialError: LocalizedError, Equatable {
    case unsupportedDevice
    case cameraDenied
    case sessionFailed(String)
    case trackingUnavailable(String)
    case workspaceUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedDevice:
            return "This device does not support world tracking."
        case .cameraDenied:
            return "HaloSpace needs camera access to build your spatial workspace."
        case .sessionFailed(let reason):
            return "The spatial session could not start. \(reason)"
        case .trackingUnavailable(let reason):
            return "Spatial tracking is limited. \(reason)"
        case .workspaceUnavailable:
            return "The spatial workspace is not available right now."
        }
    }
}

enum HaloPersistenceError: LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let detail):
            return "Could not encode HaloSpace data. \(detail)"
        case .decodingFailed(let detail):
            return "Could not read saved HaloSpace data. \(detail)"
        case .writeFailed(let detail):
            return "Could not save HaloSpace data. \(detail)"
        }
    }
}
