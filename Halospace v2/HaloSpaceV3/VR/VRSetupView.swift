//
//  VRSetupView.swift
//  HaloSpace V3
//

import CoreMotion
import SwiftUI

struct VRSetupView: View {
    let onStart: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var settings: HaloSettingsModel
    @AppStorage("halospace.vr.ipd") private var ipdOffset: Double = 14

    var body: some View {
        NavigationStack {
            ZStack {
                HaloAmbientBackground(mood: .workspace)
                VStack(spacing: 20) {
                    HaloLogoMark(size: 62, animated: true)
                    Text("VR Stereo Mode")
                        .font(HaloFont.title)
                        .foregroundStyle(HaloColor.textPrimary)
                    Text("Place your iPhone in landscape inside a compatible viewer. CoreMotion head tracking will orient your spatial windows.")
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lens Spacing (IPD Offset)")
                                .font(HaloFont.caption)
                                .foregroundStyle(HaloColor.textSecondary)
                            Spacer()
                            Text("\(Int(ipdOffset)) pt")
                                .font(HaloFont.caption)
                                .foregroundStyle(HaloColor.ice)
                        }
                        Slider(value: $ipdOffset, in: 0...32, step: 1)
                            .tint(HaloColor.ice)
                    }
                    .padding(16)
                    .haloGlass(cornerRadius: HaloRadius.md)

                    HaloPrimaryButton(title: "Start VR Session", systemImage: "play.fill", action: onStart)
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                        .foregroundStyle(HaloColor.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

@MainActor
final class VRMotionController: ObservableObject {
    @Published private(set) var yawOffset: CGFloat = 0
    @Published private(set) var pitchOffset: CGFloat = 0

    private let motionManager = CMMotionManager()
    private var referenceYaw: Double?
    private var referencePitch: Double?

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            if self.referenceYaw == nil {
                self.referenceYaw = attitude.yaw
                self.referencePitch = attitude.pitch
            }
            let dYaw = attitude.yaw - (self.referenceYaw ?? 0)
            let dPitch = attitude.pitch - (self.referencePitch ?? 0)
            self.yawOffset = CGFloat(dYaw) * 260
            self.pitchOffset = CGFloat(dPitch) * 220
        }
    }

    func recenter() {
        referenceYaw = nil
        referencePitch = nil
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct VRExperienceView: View {
    let onExit: () -> Void

    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windowManager: HaloWindowManager
    @AppStorage("halospace.vr.ipd") private var ipdOffset: Double = 14
    @StateObject private var motion = VRMotionController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            HStack(spacing: 2) {
                stereoEyeViewport(eyeShift: -CGFloat(ipdOffset))
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1)
                stereoEyeViewport(eyeShift: CGFloat(ipdOffset))
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                    }

                    Spacer()

                    Button {
                        motion.recenter()
                    } label: {
                        Label("Recenter", systemImage: "scope")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white.opacity(0.14)))
                    }
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            windowManager.prepareForSpatialEntry()
            motion.start()
        }
        .onDisappear {
            motion.stop()
        }
    }

    private func stereoEyeViewport(eyeShift: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack {
                HaloAmbientBackground(mood: .deepSpace)

                ForEach(windowManager.visibleWindows) { window in
                    let x = proxy.size.width * 0.5 + CGFloat(window.localPosition.x) * 140 + motion.yawOffset + eyeShift
                    let y = proxy.size.height * 0.5 - CGFloat(window.localPosition.y) * 120 + motion.pitchOffset
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(window.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(HaloColor.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)

                        Text("Active in VR")
                            .font(.system(size: 10))
                            .foregroundStyle(HaloColor.textSecondary)
                            .padding(.horizontal, 8)
                        Spacer()
                    }
                    .frame(width: window.logicalSize.width * 0.48, height: window.logicalSize.height * 0.48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(settings.windowTint.tintColor.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(HaloColor.ice.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .position(x: x, y: y)
                }

                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
            .clipped()
        }
    }
}
