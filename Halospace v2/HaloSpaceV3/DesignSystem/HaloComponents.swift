//
//  HaloComponents.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloIconButton: View {
    let systemName: String
    var accessibilityLabel: String
    var size: CGFloat = 44
    var tint: Color = HaloColor.textPrimary
    var isActive: Bool = false
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    HaloGlassSurface(
                        shape: Circle(),
                        tint: isActive ? HaloColor.ice.opacity(0.13) : HaloColor.glassTint,
                        strokeOpacity: isActive ? 0.28 : 0.13,
                        shadowRadius: 12
                    )
                )
                .contentShape(Circle())
        }
        .buttonStyle(HaloPressStyle(scale: 0.93, reduceMotion: reduceMotion))
        .accessibilityLabel(accessibilityLabel)
    }
}

struct HaloPrimaryButton: View {
    let title: String
    var systemImage: String = "cube.transparent"
    var subtitle: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: HaloSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(HaloFont.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(HaloFont.caption)
                            .foregroundStyle(HaloColor.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HaloColor.textSecondary)
            }
            .foregroundStyle(HaloColor.textPrimary)
            .padding(.horizontal, HaloSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.045)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.44), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.32))
                    .frame(width: 92, height: 1)
                    .blur(radius: 0.5)
                    .padding(.top, 1)
            }
            .shadow(color: Color.black.opacity(0.35), radius: 22, x: 0, y: 14)
            .shadow(color: HaloColor.ice.opacity(0.07), radius: 24, x: 0, y: 0)
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(RoundedRectangle(cornerRadius: HaloRadius.lg, style: .continuous))
        }
        .buttonStyle(HaloPressStyle(scale: 0.975, reduceMotion: reduceMotion))
        .disabled(!isEnabled)
    }
}

struct HaloSecondaryButton: View {
    let title: String
    var systemImage: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(HaloFont.subheadline)
            }
            .foregroundStyle(HaloColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                HaloGlassSurface(
                    shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                    tint: HaloColor.glassTint,
                    strokeOpacity: 0.13,
                    shadowRadius: 14
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous))
        }
        .buttonStyle(HaloPressStyle(scale: 0.97, reduceMotion: reduceMotion))
    }
}

struct HaloCard<Content: View>: View {
    var cornerRadius: CGFloat = HaloRadius.lg
    var padding: CGFloat = HaloSpacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                HaloGlassSurface(
                    shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                    tint: HaloColor.glassTint,
                    strokeOpacity: 0.12,
                    shadowRadius: 20
                )
            )
    }
}

struct HaloSectionLabel: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(HaloFont.micro)
                .tracking(1.3)
                .foregroundStyle(HaloColor.textTertiary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(HaloFont.caption)
                    .foregroundStyle(HaloColor.textTertiary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct HaloGroupedRows<Content: View>: View {
    var cornerRadius: CGFloat = HaloRadius.lg
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: HaloColor.glassTint,
                strokeOpacity: 0.11,
                shadowRadius: 18
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct HaloRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.065))
            .frame(height: 0.6)
            .padding(.leading, 52)
    }
}

struct HaloNavigationRow: View {
    let systemName: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var accent: HaloAccent = .ice
    var showsChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                HaloIconTile(systemName: systemName, accent: accent, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HaloFont.bodyMedium)
                        .foregroundStyle(HaloColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                if let value {
                    Text(value)
                        .font(HaloFont.caption)
                        .foregroundStyle(HaloColor.textTertiary)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HaloColor.textTertiary)
                }
            }
            .padding(.horizontal, HaloSpacing.md)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct HaloToggleRow: View {
    let systemName: String
    let title: String
    var subtitle: String? = nil
    var accent: HaloAccent = .ice
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 13) {
            HaloIconTile(systemName: systemName, accent: accent, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HaloFont.bodyMedium)
                    .foregroundStyle(HaloColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 10)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HaloColor.iceDeep)
        }
        .padding(.horizontal, HaloSpacing.md)
        .padding(.vertical, 11)
    }
}

struct HaloSliderRow: View {
    let title: String
    var subtitle: String? = nil
    var valueLabel: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 0.01

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HaloFont.bodyMedium)
                        .foregroundStyle(HaloColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textSecondary)
                    }
                }
                Spacer()
                Text(valueLabel)
                    .font(HaloFont.mono)
                    .foregroundStyle(HaloColor.ice)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
            }
            Slider(value: $value, in: range, step: step)
                .tint(HaloColor.ice)
        }
        .padding(.horizontal, HaloSpacing.md)
        .padding(.vertical, 13)
    }
}

struct HaloIconTile: View {
    let systemName: String
    var accent: HaloAccent = .ice
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HaloColor.accent(accent).opacity(0.20),
                            HaloColor.accent(accent).opacity(0.055)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .strokeBorder(HaloColor.accent(accent).opacity(0.22), lineWidth: 0.75)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(HaloColor.accent(accent))
        }
        .frame(width: size, height: size)
    }
}

struct HaloChip: View {
    let title: String
    var systemName: String? = nil
    var isSelected: Bool = false
    var accent: Color = HaloColor.ice
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { chipBody }
                    .buttonStyle(.plain)
            } else {
                chipBody
            }
        }
    }

    private var chipBody: some View {
        HStack(spacing: 5) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(title)
                .font(HaloFont.caption)
        }
        .foregroundStyle(isSelected ? HaloColor.textPrimary : HaloColor.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isSelected ? accent.opacity(0.18) : Color.white.opacity(0.055))
        )
        .overlay(
            Capsule().strokeBorder(
                isSelected ? accent.opacity(0.38) : Color.white.opacity(0.08),
                lineWidth: 0.7
            )
        )
    }
}

struct HaloStatusDot: View {
    var color: Color = HaloColor.success
    var isPulsing: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 16, height: 16)
                .scaleEffect(pulse ? 1.25 : 0.8)
                .opacity(pulse ? 0 : 0.8)
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.7), radius: 3)
        }
        .frame(width: 16, height: 16)
        .onAppear {
            guard isPulsing, !reduceMotion else { return }
            withAnimation(Animation.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

struct HaloSearchField: View {
    let placeholder: String
    @Binding var text: String
    var onCancel: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HaloColor.textTertiary)
            TextField(placeholder, text: $text)
                .font(HaloFont.callout)
                .foregroundStyle(HaloColor.textPrimary)
                .tint(HaloColor.ice)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(HaloColor.textTertiary)
                }
            }
            if let onCancel {
                Button("Cancel", action: onCancel)
                    .font(HaloFont.caption)
                    .foregroundStyle(HaloColor.ice)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 42)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: 14, style: .continuous),
                tint: HaloColor.glassTint,
                strokeOpacity: 0.11,
                shadowRadius: 10
            )
        )
    }
}

struct HaloEmptyState: View {
    let systemName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(HaloColor.textTertiary)
                .padding(18)
                .background(Circle().fill(Color.white.opacity(0.035)))
            Text(title)
                .font(HaloFont.headline)
                .foregroundStyle(HaloColor.textSecondary)
            Text(message)
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

struct HaloKeyValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = HaloColor.textSecondary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(HaloFont.mono)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, HaloSpacing.md)
        .padding(.vertical, 11)
    }
}
