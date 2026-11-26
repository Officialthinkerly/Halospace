//
//  AppState.swift
//  HaloSpace V3
//

import Foundation
import SwiftUI

@MainActor
final class HaloSpaceAppState: ObservableObject {
    let settings: HaloSettingsModel
    let windowManager: HaloWindowManager
    let catalog: ApplicationCatalog
    let notesStore: NotesStore
    let permissions: PermissionManager
    let router: AppRouter

    init() {
        let settings = HaloSettingsModel()
        let router = AppRouter()
        self.settings = settings
        self.windowManager = HaloWindowManager(settings: settings)
        self.catalog = ApplicationCatalog()
        self.notesStore = NotesStore()
        self.permissions = PermissionManager.shared
        self.router = router
        router.isOnboardingPresented = !settings.onboardingCompleted
    }

    func consumeOnboarding() {
        settings.onboardingCompleted = true
        router.isOnboardingPresented = false
    }

    func openApplication(_ descriptor: HaloApplicationDescriptor, fromSpatial: Bool = false) {
        let title = descriptor.name
        let payload: [String: String]
        if let url = descriptor.webURL {
            payload = ["url": url.absoluteString]
        } else if descriptor.id == HaloAppID.browser {
            payload = [:]
        } else {
            payload = [:]
        }
        let id = windowManager.open(
            applicationID: descriptor.id,
            title: title,
            size: descriptor.defaultSize,
            payload: payload
        )
        if id != nil {
            HaloHaptics.impact(.medium, enabled: settings.hapticsEnabled)
            if !fromSpatial {
                router.beginSpatial(mode: settings.performanceMode ? .ultraFast : .ar)
            }
        }
    }

    func launchSelectedExperience(_ mode: HaloLaunchMode) {
        HaloHaptics.impact(.medium, enabled: settings.hapticsEnabled)
        if mode == .vr {
            router.isVRSetupPresented = true
        } else {
            router.spatialLaunch = HaloSpatialLaunch(mode: mode)
        }
    }

    func finishExperience() {
        windowManager.flushPersistence()
        router.endSpatial()
        router.isVRExperiencePresented = false
    }
}
