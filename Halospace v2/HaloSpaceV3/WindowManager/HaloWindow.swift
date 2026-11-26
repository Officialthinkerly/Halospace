//
//  HaloWindow.swift
//  HaloSpace V3
//

import CoreGraphics
import Foundation
import simd

struct HaloVector3: Codable, Equatable {
    var x: Float
    var y: Float
    var z: Float

    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(_ value: SIMD3<Float>) {
        self.init(x: value.x, y: value.y, z: value.z)
    }

    var simdValue: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }

    static let zero = HaloVector3(x: 0, y: 0, z: 0)
}

struct HaloWindowSize: Codable, Equatable {
    var width: Double
    var height: Double

    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    init(_ size: CGSize) {
        self.init(width: Double(size.width), height: Double(size.height))
    }

    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }

    var aspectRatio: Double {
        guard height > 0 else { return 4.0 / 3.0 }
        return width / height
    }
}

enum HaloWindowMetrics {
    static let minimumSize = CGSize(width: 280, height: 190)
    static let maximumSize = CGSize(width: 640, height: 560)
    static let defaultSize = CGSize(width: 380, height: 268)
    static let metersPerPoint: Float = 0.00305
    static let maxWindows = 6
    static let minDistance: Float = 1.0
    static let maxDistance: Float = 2.8
    static let horizontalRange: ClosedRange<Float> = -1.45...1.45
    static let verticalRange: ClosedRange<Float> = -0.95...0.95
    static let depthRange: ClosedRange<Float> = -1.2...0.42

    static func physicalWidth(for size: HaloWindowSize) -> Float {
        Float(size.width) * metersPerPoint
    }

    static func physicalHeight(for size: HaloWindowSize) -> Float {
        Float(size.height) * metersPerPoint
    }

    static func clamped(_ size: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, minimumSize.width), maximumSize.width),
            height: min(max(size.height, minimumSize.height), maximumSize.height)
        )
    }
}

struct HaloWindowModel: Identifiable, Codable, Equatable {
    let id: UUID
    var applicationID: String
    var title: String
    var localPosition: HaloVector3
    var localYaw: Float
    var logicalSize: HaloWindowSize
    var isMinimized: Bool
    var zIndex: Int
    var payload: [String: String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        applicationID: String,
        title: String,
        localPosition: HaloVector3 = .zero,
        localYaw: Float = 0,
        logicalSize: HaloWindowSize = HaloWindowSize(HaloWindowMetrics.defaultSize),
        isMinimized: Bool = false,
        zIndex: Int = 0,
        payload: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.applicationID = applicationID
        self.title = title
        self.localPosition = localPosition
        self.localYaw = localYaw
        self.logicalSize = logicalSize
        self.isMinimized = isMinimized
        self.zIndex = zIndex
        self.payload = payload
        self.createdAt = createdAt
    }

    var estimatedDistanceFromAnchor: Float {
        max(0.7, abs(localPosition.z))
    }
}
