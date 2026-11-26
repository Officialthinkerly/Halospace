//
//  HaloTabBar.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloTabBar: View {
    @Binding var selection: HaloTab
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 4) {
            ForEach(HaloTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(5)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: 26, style: .continuous),
                tint: Color.white.opacity(0.03),
                strokeOpacity: 0.16,
                shadowRadius: 28
            )
        )
        .padding(.horizontal, 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("HaloSpace navigation")
    }

    private func tabButton(_ tab: HaloTab) -> some View {
        Button {
            guard selection != tab else { return }
            HaloHaptics.selection(enabled: true)
            withAnimation(HaloMotion.snappy) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: selection == tab ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 21)
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .medium))
                    .tracking(0.2)
            }
            .foregroundStyle(selection == tab ? HaloColor.textPrimary : HaloColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if selection == tab {
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.13), Color.white.opacity(0.035)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                        )
                        .matchedGeometryEffect(id: "selectedTab", in: indicator)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}
