//
//  SettingsScaffold.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloSettingsPage<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            HaloAmbientBackground(mood: .workspace)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let subtitle {
                        Text(subtitle)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HaloSegmentedOptions<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = selection == option
                Button {
                    guard !isSelected else { return }
                    HaloHaptics.selection(enabled: settings.hapticsEnabled)
                    withAnimation(HaloMotion.snappy) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(isSelected ? HaloColor.textPrimary : HaloColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                                    )
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }
}

struct HaloRadioRow: View {
    let title: String
    var detail: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HaloFont.bodyMedium)
                        .foregroundStyle(HaloColor.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(HaloFont.footnote)
                            .foregroundStyle(HaloColor.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? HaloColor.ice : Color.white.opacity(0.20), lineWidth: isSelected ? 5.5 : 1)
                        .frame(width: 18, height: 18)
                }
            }
            .padding(.horizontal, HaloSpacing.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct HaloActionTile: View {
    let title: String
    let systemName: String
    var accent: HaloAccent = .ice
    var isDestructive: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @EnvironmentObject private var settings: HaloSettingsModel

    var body: some View {
        Button {
            guard isEnabled else { return }
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            action()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isDestructive ? HaloColor.danger : HaloColor.accent(accent))
                Text(title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(isDestructive ? HaloColor.danger : HaloColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isEnabled ? 0.04 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.6)
                    )
            )
            .opacity(isEnabled ? 1 : 0.38)
        }
        .buttonStyle(HaloPressStyle(scale: 0.96))
        .disabled(!isEnabled)
    }
}

struct HaloInfoNote: View {
    let systemName: String
    let message: String
    var accent: HaloAccent = .ice

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HaloColor.accent(accent))
                .padding(.top, 1)
            Text(message)
                .font(HaloFont.footnote)
                .foregroundStyle(HaloColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}
