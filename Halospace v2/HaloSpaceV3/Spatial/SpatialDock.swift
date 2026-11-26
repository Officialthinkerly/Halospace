//
//  SpatialDock.swift
//  HaloSpace V3
//

import SwiftUI

struct SpatialDock: View {
    let onRecenter: () -> Void
    let onTidy: () -> Void

    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var catalog: ApplicationCatalog
    @EnvironmentObject private var windowManager: HaloWindowManager
    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        VStack(spacing: 8) {
            if !windowManager.minimizedWindows.isEmpty {
                minimizedStrip
            }

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(catalog.allApplications) { app in
                            dockAppButton(app)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Divider()
                    .frame(height: 26)
                    .background(Color.white.opacity(0.14))

                Button(action: onRecenter) {
                    Image(systemName: "scope")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HaloColor.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Recenter workspace")

                Button(action: onTidy) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HaloColor.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tidy windows")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                HaloGlassSurface(
                    shape: Capsule(),
                    tint: Color.black.opacity(0.45),
                    strokeOpacity: 0.22,
                    shadowRadius: 22
                )
            )
        }
        .padding(.horizontal, 16)
    }

    private func dockAppButton(_ app: HaloApplicationDescriptor) -> some View {
        let isOpen = windowManager.windows.contains { $0.applicationID == app.id && !$0.isMinimized }
        return Button {
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            appState.openApplication(app, fromSpatial: true)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: app.iconSystemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HaloColor.accent(app.accent))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(isOpen ? 0.14 : 0.06))
                    )
                Circle()
                    .fill(isOpen ? HaloColor.ice : .clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(app.name)")
    }

    private var minimizedStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(windowManager.minimizedWindows) { window in
                    Button {
                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                        windowManager.restore(window.id)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(window.title)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(HaloColor.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}
