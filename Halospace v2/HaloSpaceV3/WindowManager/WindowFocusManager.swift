//
//  WindowFocusManager.swift
//  HaloSpace V3
//

import Foundation

enum HaloWindowOrdering {
    static func topmostWindow(in windows: [HaloWindowModel], containing point: CGPoint, frames: [UUID: CGRect]) -> UUID? {
        let candidates = windows
            .filter { !$0.isMinimized }
            .sorted { $0.zIndex > $1.zIndex }
        return candidates.first { window in
            frames[window.id]?.contains(point) == true
        }?.id
    }

    static func nextFocus(after closingID: UUID, windows: [HaloWindowModel]) -> UUID? {
        windows
            .filter { $0.id != closingID && !$0.isMinimized }
            .max { $0.zIndex < $1.zIndex }?
            .id
    }
}

struct HaloWindowDragState: Equatable {
    var windowID: UUID
    var initialPosition: HaloVector3
    var lastScreenLocation: CGPoint
    var hasMoved: Bool = false
}

struct HaloWindowResizeState: Equatable {
    var windowID: UUID
    var initialSize: HaloWindowSize
    var initialLocation: CGPoint
}
