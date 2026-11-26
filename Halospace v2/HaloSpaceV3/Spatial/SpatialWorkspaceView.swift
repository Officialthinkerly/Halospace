//
//  SpatialWorkspaceView.swift
//  HaloSpace V3
//
//  The spatial workspace is implemented in SpatialWorkspaceRoot.swift.
//  This file intentionally remains small so the session, scene and window
//  layers can evolve independently.
//

import SwiftUI

struct SpatialWorkspaceView: View {
    let launchMode: HaloLaunchMode
    let onExit: () -> Void

    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        SpatialWorkspaceRoot(launchMode: launchMode, onExit: onExit)
            .environmentObject(appState)
            .environmentObject(settings)
            .environmentObject(appState.windowManager)
            .environmentObject(appState.catalog)
            .environmentObject(appState.notesStore)
            .environmentObject(appState.permissions)
    }
}
