//
//  SpatialWindowContainer.swift
//  HaloSpace V3
//

import SwiftUI

struct SpatialWindowContainer: View {
    let window: HaloWindowModel
    let isFocused: Bool
    let projectedScale: CGFloat
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMoveDelta: (CGSize) -> Void
    let onResize: (CGSize) -> Void

    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var catalog: ApplicationCatalog

    @State private var dragTranslation: CGSize = .zero
    @State private var initialResizeSize: CGSize?

    private var descriptor: HaloApplicationDescriptor? {
        catalog.descriptor(for: window.applicationID)
    }

    private var effectiveScale: CGFloat {
        projectedScale * CGFloat(settings.windowScale)
    }

    var body: some View {
        let size = window.logicalSize.cgSize

        VStack(spacing: 0) {
            titleBar
            Divider().background(Color.white.opacity(0.08))
            SpatialAppContentView(window: window)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: HaloRadius.window, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HaloRadius.window, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isFocused
                            ? [HaloColor.ice.opacity(0.75), Color.white.opacity(0.18), HaloColor.ice.opacity(0.32)]
                            : [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isFocused ? 1.4 : 0.8
                )
        )
        .overlay(alignment: .bottomTrailing) {
            resizeHandle(currentSize: size)
        }
        .shadow(color: Color.black.opacity(isFocused ? 0.55 : 0.35), radius: isFocused ? 24 : 14, y: 12)
        .scaleEffect(effectiveScale)
        .offset(dragTranslation)
        .contentShape(RoundedRectangle(cornerRadius: HaloRadius.window, style: .continuous))
        .simultaneousGesture(
            TapGesture().onEnded {
                if !isFocused {
                    onFocus()
                }
            }
        )
    }

    private var windowBackground: some View {
        let opacity = max(0.35, min(0.96, settings.uiTransparency))
        return ZStack {
            settings.windowTint.tintColor.opacity(opacity)
            Rectangle().fill(.ultraThinMaterial.opacity(0.45))
        }
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            if let descriptor {
                Image(systemName: descriptor.iconSystemName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HaloColor.accent(descriptor.accent))
            }

            if settings.showWindowLabels {
                Text(window.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Capsule()
                .fill(Color.white.opacity(isFocused ? 0.35 : 0.16))
                .frame(width: 28, height: 3.5)

            Spacer(minLength: 6)

            Button(action: onMinimize) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HaloColor.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Minimize \(window.title)")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HaloColor.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close \(window.title)")
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if !isFocused { onFocus() }
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    onMoveDelta(value.translation)
                    dragTranslation = .zero
                }
        )
    }

    private func resizeHandle(currentSize: CGSize) -> some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(HaloColor.textTertiary)
            .padding(6)
            .background(Circle().fill(Color.white.opacity(0.06)))
            .padding(6)
            .contentShape(Rectangle().inset(by: -8))
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if initialResizeSize == nil {
                            initialResizeSize = currentSize
                            if !isFocused { onFocus() }
                        }
                        guard let base = initialResizeSize else { return }
                        let scale = max(0.5, effectiveScale)
                        let nextSize = CGSize(
                            width: base.width + value.translation.width / scale,
                            height: base.height + value.translation.height / scale
                        )
                        onResize(nextSize)
                    }
                    .onEnded { _ in
                        initialResizeSize = nil
                    }
            )
            .accessibilityLabel("Resize \(window.title)")
    }
}
