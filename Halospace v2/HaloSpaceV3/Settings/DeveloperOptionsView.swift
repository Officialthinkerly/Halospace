//
//  DeveloperOptionsView.swift
//  HaloSpace V3
//

import SwiftUI
import UIKit

struct DeveloperOptionsView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var permissions: PermissionManager
    @EnvironmentObject private var windows: HaloWindowManager
    @ObservedObject private var diagnostics = SpatialDiagnosticsCenter.shared

    @State private var copiedReport = false
    @State private var showResetConfirmation = false

    var body: some View {
        HaloSettingsPage(
            title: "Developer Options",
            subtitle: "Diagnostics reflect the most recent spatial session. Live values update while the workspace is open."
        ) {
            VStack(spacing: 9) {
                HaloSectionLabel(title: "Runtime")
                HaloGroupedRows {
                    Group {
                        HaloKeyValueRow(label: "AR world tracking", value: permissions.arSupported ? "Supported" : "Unsupported")
                        HaloRowDivider()
                        HaloKeyValueRow(label: "LiDAR scene mesh", value: permissions.lidarSupported ? "Supported" : "Not available")
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Camera permission", value: permissions.camera.title)
                    }
                    Group {
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Device", value: HaloDeviceInfo.modelIdentifier)
                        HaloRowDivider()
                        HaloKeyValueRow(
                            label: "OS",
                            value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
                        )
                    }
                    Group {
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Chosen launch mode", value: settings.defaultLaunchMode.compactTitle)
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Performance mode", value: settings.performanceMode ? "Ultra Fast" : "Standard")
                    }
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Last spatial session", trailing: diagnostics.snapshot.isActive ? "Live" : "Stored")
                HaloGroupedRows {
                    Group {
                        HaloKeyValueRow(label: "Session", value: diagnostics.snapshot.sessionState)
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Workspace mode", value: diagnostics.snapshot.mode)
                        HaloRowDivider()
                        HaloKeyValueRow(label: "World tracking", value: diagnostics.snapshot.trackingState)
                    }
                    Group {
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Camera FPS", value: String(format: "%.1f", diagnostics.snapshot.cameraFPS))
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Display FPS", value: String(format: "%.1f", diagnostics.snapshot.renderFPS))
                        HaloRowDivider()
                        HaloKeyValueRow(
                            label: "Hand tracking",
                            value: diagnostics.snapshot.handTrackingState
                        )
                    }
                    Group {
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Hand tracking FPS", value: String(format: "%.1f", diagnostics.snapshot.handTrackingFPS))
                        HaloRowDivider()
                        HaloKeyValueRow(label: "Open windows", value: "\(windows.windows.count)")
                        HaloRowDivider()
                        HaloKeyValueRow(label: "RealityKit entities", value: "\(diagnostics.snapshot.entityCount)")
                        if let error = diagnostics.snapshot.lastError {
                            HaloRowDivider()
                            HaloKeyValueRow(label: "Last error", value: error, valueColor: HaloColor.danger)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                HaloActionTile(title: copiedReport ? "Copied" : "Copy Report", systemName: copiedReport ? "checkmark" : "doc.on.doc", accent: .mint) {
                    copyReport()
                }
                HaloActionTile(title: "Enter Space", systemName: "cube.transparent", accent: .ice) {
                    appState.launchSelectedExperience(settings.defaultLaunchMode)
                }
                HaloActionTile(title: "Clear", systemName: "trash", accent: .silver) {
                    SpatialDiagnosticsCenter.shared.reset()
                    HaloHaptics.selection(enabled: settings.hapticsEnabled)
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Debugging")
                HaloGroupedRows {
                    HaloToggleRow(
                        systemName: "ladybug",
                        title: "Verbose logging",
                        subtitle: "Write spatial, tracking and persistence events to the system log.",
                        accent: .amber,
                        isOn: Binding(
                            get: { settings.debugLoggingEnabled },
                            set: { settings.setDebugLogging($0) }
                        )
                    )
                    HaloRowDivider()
                    HaloToggleRow(
                        systemName: "gauge",
                        title: "Diagnostics overlay",
                        subtitle: "Show live session and FPS information inside the spatial workspace.",
                        accent: .mint,
                        isOn: $settings.showDiagnosticsOverlay
                    )
                    HaloRowDivider()
                    HaloToggleRow(
                        systemName: "hammer",
                        title: "Developer options enabled",
                        subtitle: "Turn off to hide this screen again.",
                        accent: .violet,
                        isOn: $settings.developerModeUnlocked
                    )
                }
            }

            HaloGroupedRows {
                HaloNavigationRow(
                    systemName: "arrow.counterclockwise",
                    title: "Reset all settings and workspace",
                    subtitle: "Close windows and restore every preference to default.",
                    accent: .amber
                ) {
                    showResetConfirmation = true
                }
            }

            HaloInfoNote(
                systemName: "info.circle",
                message: "FPS values are measured from camera frame callbacks and display refresh cadence. They are indicative, not a substitute for Instruments profiling. Hand tracking is provided by Apple Vision and processes camera frames locally."
            )
        }
        .confirmationDialog(
            "Reset all HaloSpace data?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                windows.resetWorkspace()
                settings.resetToDefaults()
                SpatialDiagnosticsCenter.shared.reset()
                HaloHaptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Settings, window layout and diagnostics will be reset. Notes and web apps are not removed.")
        }
    }

    private func copyReport() {
        let report = diagnostics.makeReport(deviceSummary: HaloDeviceInfo.summary)
        UIPasteboard.general.string = report
        copiedReport = true
        HaloHaptics.success(enabled: settings.hapticsEnabled)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedReport = false
        }
    }
}
