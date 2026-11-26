//
//  RootView.swift
//  HaloSpace V3
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem {
                    Label(HaloTab.home.title, systemImage: HaloTab.home.systemImage)
                }
                .tag(HaloTab.home)

            ApplicationsView()
                .tabItem {
                    Label(HaloTab.apps.title, systemImage: HaloTab.apps.systemImage)
                }
                .tag(HaloTab.apps)

            SettingsView()
                .tabItem {
                    Label(HaloTab.settings.title, systemImage: HaloTab.settings.systemImage)
                }
                .tag(HaloTab.settings)
        }
        .background(HaloColor.void.ignoresSafeArea())
        .fullScreenCover(isPresented: $router.isOnboardingPresented) {
            OnboardingView {
                appState.consumeOnboarding()
            }
            .environmentObject(appState)
            .environmentObject(settings)
        }
        .fullScreenCover(item: $router.spatialLaunch) { launch in
            SpatialWorkspaceView(launchMode: launch.mode, onExit: {
                appState.finishExperience()
            })
            .environmentObject(appState)
            .environmentObject(settings)
            .environmentObject(appState.windowManager)
            .environmentObject(appState.catalog)
            .environmentObject(appState.notesStore)
        }
        .sheet(isPresented: $router.isVRSetupPresented) {
            VRSetupView(
                onStart: {
                    router.isVRSetupPresented = false
                    router.isVRExperiencePresented = true
                },
                onCancel: {
                    router.isVRSetupPresented = false
                }
            )
            .environmentObject(settings)
        }
        .fullScreenCover(isPresented: $router.isVRExperiencePresented) {
            VRExperienceView(onExit: {
                router.isVRExperiencePresented = false
            })
            .environmentObject(settings)
            .environmentObject(appState.windowManager)
        }
    }

}
