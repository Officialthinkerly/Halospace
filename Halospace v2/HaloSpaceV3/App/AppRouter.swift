//
//  AppRouter.swift
//  HaloSpace V3
//

import Foundation
import SwiftUI

enum HaloTab: String, CaseIterable, Identifiable {
    case home
    case apps
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .apps: return "Apps"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "circle.hexagongrid"
        case .apps: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }
}

enum HomeRoute: Hashable {
    case controlCenter
    case windowManager
}

enum SettingsRoute: Hashable {
    case spatial
    case gestures
    case appearance
    case privacy
    case windowManager
    case controlCenter
    case developer
    case about
}

struct HaloSpatialLaunch: Identifiable, Equatable {
    let id = UUID()
    let mode: HaloLaunchMode
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: HaloTab = .home
    @Published var homePath: [HomeRoute] = []
    @Published var settingsPath: [SettingsRoute] = []
    @Published var spatialLaunch: HaloSpatialLaunch?
    @Published var isVRSetupPresented = false
    @Published var isVRExperiencePresented = false
    @Published var isOnboardingPresented = false
    @Published var isSpatialAppLibraryPresented = false

    func openControlCenter() {
        if homePath.last != .controlCenter {
            homePath.append(.controlCenter)
        }
    }

    func openSettings(_ route: SettingsRoute? = nil) {
        selectedTab = .settings
        if let route {
            settingsPath = [route]
        } else {
            settingsPath = []
        }
    }

    func returnHome() {
        selectedTab = .home
        settingsPath = []
    }

    func beginSpatial(mode: HaloLaunchMode) {
        if mode == .vr {
            isVRSetupPresented = true
        } else {
            spatialLaunch = HaloSpatialLaunch(mode: mode)
        }
    }

    func endSpatial() {
        spatialLaunch = nil
    }
}
