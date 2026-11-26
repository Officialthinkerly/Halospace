//
//  AboutHaloSpaceView.swift
//  HaloSpace V3
//

import SwiftUI

struct AboutHaloSpaceView: View {
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var permissions: PermissionManager

    @State private var versionTapCount = 0
    @State private var showPrivacySheet = false
    @State private var unlockPulse = false

    var body: some View {
        HaloSettingsPage(title: "About HaloSpace") {
            VStack(spacing: 9) {
                HaloLogoMark(size: 82, animated: true, glowIntensity: 0.7)
                    .frame(height: 120)
                HaloWordmark(size: 27)
                Text(HaloBrand.shortDescription)
                    .font(HaloFont.footnote)
                    .foregroundStyle(HaloColor.textSecondary)
                    .padding(.top, -3)

                HStack(spacing: 6) {
                    Text("VERSION \(HaloBrand.version)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(HaloColor.ice)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(HaloColor.ice.opacity(0.10)))
                    Text("BUILD \(HaloBrand.buildNumber)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(HaloColor.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.045)))
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .scaleEffect(unlockPulse ? 1.02 : 1)

            Text(HaloBrand.longDescription)
                .font(HaloFont.callout)
                .foregroundStyle(HaloColor.textSecondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Application")
                HaloGroupedRows {
                    HaloKeyValueRow(label: "Version", value: HaloBrand.version)
                    HaloRowDivider()
                    Button {
                        registerVersionTap()
                    } label: {
                        HaloKeyValueRow(label: "Build", value: HaloBrand.buildNumber)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Bundle", value: HaloBrand.bundleIdentifier)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Minimum iOS", value: "16.0")
                    HaloRowDivider()
                    HaloKeyValueRow(
                        label: "Spatial engine",
                        value: permissions.arSupported ? "ARKit + RealityKit" : "Preview renderer"
                    )
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Privacy")
                HaloGroupedRows {
                    HaloNavigationRow(
                        systemName: "lock.shield",
                        title: "Privacy Information",
                        subtitle: "Camera, hand tracking and local data",
                        accent: .mint
                    ) {
                        showPrivacySheet = true
                    }
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Camera data", value: "On-device only", valueColor: HaloColor.success)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Hand data", value: "On-device only", valueColor: HaloColor.success)
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Analytics", value: "None", valueColor: HaloColor.success)
                }
            }

            VStack(spacing: 9) {
                HaloSectionLabel(title: "Built with")
                HaloGroupedRows {
                    HaloKeyValueRow(label: "Interface", value: "SwiftUI")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Spatial rendering", value: "ARKit · RealityKit")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Hand tracking", value: "Vision")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Web engine", value: "WebKit")
                    HaloRowDivider()
                    HaloKeyValueRow(label: "Motion", value: "CoreMotion")
                }
            }

            HaloInfoNote(
                systemName: "exclamationmark.circle",
                message: "HaloSpace is an independent spatial computing project. It is not affiliated with, endorsed by or sponsored by Apple Inc. Apple, iPhone, ARKit, RealityKit, Vision and related marks are trademarks of Apple Inc."
            )

            if settings.developerModeUnlocked {
                HaloGroupedRows {
                    HaloKeyValueRow(label: "Developer options", value: "Enabled", valueColor: HaloColor.success)
                }
            }

            Text("Tap the build number seven times to enable developer options.")
                .font(.system(size: 10))
                .foregroundStyle(HaloColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyInformationSheet()
                .environmentObject(settings)
        }
    }

    private func registerVersionTap() {
        guard !settings.developerModeUnlocked else { return }
        versionTapCount += 1
        HaloHaptics.selection(enabled: settings.hapticsEnabled)
        if versionTapCount >= 7 {
            settings.developerModeUnlocked = true
            HaloHaptics.success(enabled: settings.hapticsEnabled)
            withAnimation(HaloMotion.snappy) { unlockPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(HaloMotion.gentle) { unlockPulse = false }
            }
        }
    }
}

struct PrivacyInformationSheet: View {
    @EnvironmentObject private var settings: HaloSettingsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                HaloAmbientBackground(mood: .workspace)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        privacySection(
                            icon: "camera",
                            title: "Camera",
                            body: "HaloSpace uses the rear camera exclusively to render your physical surroundings through ARKit and to estimate hand gestures with Apple Vision. Frames are processed in memory, are never recorded, and never leave your iPhone."
                        )
                        privacySection(
                            icon: "hand.point.up.left",
                            title: "Hand tracking",
                            body: "Hand-pose landmarks are estimated on-device from camera frames. HaloSpace only derives simple pinch and drag interactions. Hand data is not stored after a frame is processed."
                        )
                        privacySection(
                            icon: "internaldrive",
                            title: "Local data",
                            body: "Window layouts, notes, settings and web app wrappers are stored in HaloSpace's local app container on this iPhone. You can delete this data from Privacy & Security or by deleting the app."
                        )
                        privacySection(
                            icon: "photo",
                            title: "Photos",
                            body: "Halo Photos uses Apple's system photo picker. HaloSpace only receives the images you explicitly select and does not request access to your entire library."
                        )
                        privacySection(
                            icon: "network.slash",
                            title: "Network",
                            body: "HaloSpace has no accounts, advertising, analytics or tracking SDKs. Websites you open in Halo Browser or spatial web apps load directly from the web, subject to each site's own privacy practices."
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How HaloSpace Handles Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HaloColor.ice)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func privacySection(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HaloIconTile(systemName: icon, accent: .ice, size: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(HaloFont.headline)
                    .foregroundStyle(HaloColor.textPrimary)
                Text(body)
                    .font(HaloFont.footnote)
                    .foregroundStyle(HaloColor.textSecondary)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
