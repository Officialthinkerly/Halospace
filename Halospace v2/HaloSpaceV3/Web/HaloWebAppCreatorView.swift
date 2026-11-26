//
//  HaloWebAppCreatorView.swift
//  HaloSpace V3
//

import SwiftUI

struct HaloWebAppCreatorView: View {
    @EnvironmentObject private var catalog: ApplicationCatalog
    @EnvironmentObject private var settings: HaloSettingsModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var urlString = ""
    @State private var iconSystemName = "globe"
    @State private var accent: HaloAccent = .ice
    @State private var errorMessage: String?

    private let iconOptions = [
        "globe", "safari", "doc.text", "book", "newspaper",
        "cart", "music.note", "play.rectangle", "map", "sparkles",
        "terminal", "graduationcap"
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validatedURL: URL? {
        HaloLinkParser.validatedWebAppURL(from: urlString)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && validatedURL != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaloAmbientBackground(mood: .workspace)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        previewCard

                        VStack(alignment: .leading, spacing: 8) {
                            HaloSectionLabel(title: "Name")
                            fieldContainer {
                                TextField("My Web App", text: $name)
                                    .font(HaloFont.body)
                                    .foregroundStyle(HaloColor.textPrimary)
                                    .tint(HaloColor.ice)
                                    .textInputAutocapitalization(.words)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HaloSectionLabel(title: "Website URL")
                            fieldContainer {
                                TextField("example.com", text: $urlString)
                                    .font(HaloFont.body)
                                    .foregroundStyle(HaloColor.textPrimary)
                                    .tint(HaloColor.ice)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            }
                            Text("HaloSpace wraps this website in a spatial window. It is not converted into a native iOS app.")
                                .font(HaloFont.footnote)
                                .foregroundStyle(HaloColor.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 9) {
                            HaloSectionLabel(title: "Icon")
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                                spacing: 8
                            ) {
                                ForEach(iconOptions, id: \.self) { option in
                                    Button {
                                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                                        iconSystemName = option
                                    } label: {
                                        Image(systemName: option)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(iconSystemName == option ? HaloColor.accent(accent) : HaloColor.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 42)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(iconSystemName == option ? HaloColor.accent(accent).opacity(0.12) : Color.white.opacity(0.035))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        iconSystemName == option ? HaloColor.accent(accent).opacity(0.35) : Color.white.opacity(0.06),
                                                        lineWidth: 0.7
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 9) {
                            HaloSectionLabel(title: "Accent")
                            HStack(spacing: 12) {
                                ForEach(HaloAccent.allCases, id: \.self) { option in
                                    Button {
                                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                                        accent = option
                                    } label: {
                                        Circle()
                                            .fill(HaloColor.accent(option))
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.white.opacity(accent == option ? 0.9 : 0.15), lineWidth: accent == option ? 2 : 0.8)
                                            )
                                            .frame(width: 38, height: 38)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(option.rawValue.capitalized)
                                }
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(HaloFont.footnote)
                                .foregroundStyle(HaloColor.danger)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Web App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HaloColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .font(HaloFont.subheadline)
                        .foregroundStyle(canSave ? HaloColor.ice : HaloColor.textTertiary)
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var previewCard: some View {
        HStack(spacing: 13) {
            HaloIconTile(systemName: iconSystemName, accent: accent, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(trimmedName.isEmpty ? "Your Web App" : trimmedName)
                    .font(HaloFont.headline)
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineLimit(1)
                Text(validatedURL?.host?.replacingOccurrences(of: "www.", with: "") ?? "Add a website URL")
                    .font(HaloFont.footnote)
                    .foregroundStyle(HaloColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("WEB")
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(HaloColor.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.055)))
        }
        .padding(14)
        .background(
            HaloGlassSurface(
                shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                tint: Color.white.opacity(0.03),
                strokeOpacity: 0.11,
                shadowRadius: 12
            )
        )
    }

    private func fieldContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.7)
                    )
            )
    }

    private func create() {
        guard let url = validatedURL else {
            errorMessage = "Enter a valid http or https website address."
            return
        }
        if catalog.addWebApplication(
            name: trimmedName,
            urlString: url.absoluteString,
            iconSystemName: iconSystemName,
            accent: accent
        ) != nil {
            HaloHaptics.success(enabled: settings.hapticsEnabled)
            dismiss()
        } else {
            errorMessage = "HaloSpace could not create this web app. Check the name and URL."
            HaloHaptics.error(enabled: settings.hapticsEnabled)
        }
    }
}
