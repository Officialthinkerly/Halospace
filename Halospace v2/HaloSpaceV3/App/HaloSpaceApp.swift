//
//  HaloSpaceApp.swift
//  HaloSpace V3
//

import SwiftUI

@main
struct HaloSpaceApp: App {
    @StateObject private var appState = HaloSpaceAppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.settings)
                .environmentObject(appState.windowManager)
                .environmentObject(appState.catalog)
                .environmentObject(appState.notesStore)
                .environmentObject(appState.permissions)
                .environmentObject(appState.router)
                .preferredColorScheme(.dark)
                .tint(HaloColor.ice)
        }
    }
}
