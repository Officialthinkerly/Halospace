//
//  ApplicationsView.swift
//  HaloSpace V3
//

import SwiftUI

enum HaloAppFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case builtIn = "Built-in"
    case web = "Web"

    var id: String { rawValue }
}

struct ApplicationsView: View {
    @EnvironmentObject private var appState: HaloSpaceAppState
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var catalog: ApplicationCatalog

    @State private var searchText = ""
    @State private var filter: HaloAppFilter = .all
    @State private var showWebAppCreator = false

    var body: some View {
        NavigationStack {
            ZStack {
                HaloAmbientBackground(mood: .workspace)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        libraryIntro
                        filterRow
                        libraryGrid
                        createCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Applications")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search applications"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HaloHaptics.selection(enabled: settings.hapticsEnabled)
                        showWebAppCreator = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Create a spatial web app")
                    .accessibilityIdentifier("apps.createWebApp")
                }
            }
            .sheet(isPresented: $showWebAppCreator) {
                HaloWebAppCreatorView()
                    .environmentObject(catalog)
                    .environmentObject(settings)
            }
        }
    }

    private var libraryIntro: some View {
        Text("\(catalog.allApplications.count) spatial apps available")
            .font(HaloFont.footnote)
            .foregroundStyle(HaloColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private var filterRow: some View {
        HStack(spacing: 7) {
            ForEach(HaloAppFilter.allCases) { item in
                HaloChip(
                    title: item.rawValue,
                    isSelected: filter == item,
                    accent: HaloColor.ice
                ) {
                    HaloHaptics.selection(enabled: settings.hapticsEnabled)
                    withAnimation(HaloMotion.snappy) { filter = item }
                }
            }
            Spacer()
        }
    }

    private var filteredApps: [HaloApplicationDescriptor] {
        let base = filter == .web
            ? catalog.allApplications.filter(\.isWebApplication)
            : filter == .builtIn
                ? catalog.allApplications.filter { !$0.isWebApplication }
                : catalog.allApplications
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.summary.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var libraryGrid: some View {
        Group {
            if filteredApps.isEmpty {
                HaloEmptyState(
                    systemName: filter == .web ? "globe" : "square.grid.2x2",
                    title: filter == .web ? "No web apps yet" : "No applications found",
                    message: filter == .web
                        ? "Create a spatial web app from any website URL."
                        : "Try a different search term."
                )
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)],
                    spacing: 11
                ) {
                    ForEach(filteredApps) { app in
                        ApplicationTile(app: app) {
                            launch(app)
                        }
                        .contextMenu {
                            if app.isWebApplication,
                               let web = catalog.webApplication(withApplicationID: app.id) {
                                Button(role: .destructive) {
                                    catalog.deleteWebApplication(id: web.id)
                                } label: {
                                    Label("Remove Web App", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .animation(HaloMotion.quick, value: filter)
    }

    private var createCard: some View {
        Button {
            HaloHaptics.selection(enabled: settings.hapticsEnabled)
            showWebAppCreator = true
        } label: {
            HStack(spacing: 13) {
                HaloIconTile(systemName: "globe.badge.chevron.backward", accent: .violet, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bring a website into your space")
                        .font(HaloFont.bodyMedium)
                        .foregroundStyle(HaloColor.textPrimary)
                    Text("Create a spatial web app wrapper. It opens in Halo Browser's web engine, not as a native app.")
                        .font(HaloFont.footnote)
                        .foregroundStyle(HaloColor.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HaloColor.textTertiary)
            }
            .padding(14)
            .background(
                HaloGlassSurface(
                    shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                    tint: Color.white.opacity(0.025),
                    strokeOpacity: 0.10,
                    shadowRadius: 14
                )
            )
        }
        .buttonStyle(HaloPressStyle(scale: 0.985))
        .padding(.top, 4)
    }

    private func launch(_ app: HaloApplicationDescriptor) {
        HaloHaptics.impact(.medium, enabled: settings.hapticsEnabled)
        appState.openApplication(app)
    }
}

struct ApplicationTile: View {
    let app: HaloApplicationDescriptor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HaloIconTile(systemName: app.iconSystemName, accent: app.accent, size: 44)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(HaloColor.textTertiary)
                }

                Spacer(minLength: 12)

                Text(app.name)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(HaloColor.textPrimary)
                    .lineLimit(1)

                Text(app.summary)
                    .font(.system(size: 10.5))
                    .foregroundStyle(HaloColor.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 28, alignment: .top)
                    .padding(.top, 2)

                HStack(spacing: 4) {
                    Text(app.category.title.uppercased())
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(0.8)
                    if app.isWebApplication {
                        Circle().fill(HaloColor.violet.opacity(0.7)).frame(width: 3, height: 3)
                    }
                }
                .foregroundStyle(app.isWebApplication ? HaloColor.violet.opacity(0.8) : HaloColor.textTertiary)
                .padding(.top, 8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(
                HaloGlassSurface(
                    shape: RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous),
                    tint: Color.white.opacity(0.028),
                    strokeOpacity: 0.11,
                    shadowRadius: 14
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: HaloRadius.md, style: .continuous))
        }
        .buttonStyle(HaloPressStyle(scale: 0.97))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.name). \(app.summary)")
        .accessibilityHint("Opens this application in your spatial workspace")
    }
}
