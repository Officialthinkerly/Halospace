//
//  ApplicationRegistry.swift
//  HaloSpace V3
//

import Foundation
import SwiftUI

enum HaloAppCategory: String, Codable, CaseIterable {
    case browser
    case productivity
    case media
    case utility
    case settings
    case web

    var title: String {
        switch self {
        case .browser: return "Browser"
        case .productivity: return "Productivity"
        case .media: return "Media"
        case .utility: return "Utility"
        case .settings: return "System"
        case .web: return "Web App"
        }
    }
}

struct HaloApplicationDescriptor: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let iconSystemName: String
    let accent: HaloAccent
    let category: HaloAppCategory
    let defaultWidth: Double
    let defaultHeight: Double
    let supportsMultipleWindows: Bool
    var webURL: URL? = nil

    var defaultSize: CGSize {
        CGSize(width: defaultWidth, height: defaultHeight)
    }

    var isWebApplication: Bool {
        webURL != nil
    }

    static let browser = HaloApplicationDescriptor(
        id: HaloAppID.browser,
        name: "Halo Browser",
        summary: "The web, floating in your space.",
        iconSystemName: "safari",
        accent: .ice,
        category: .browser,
        defaultWidth: 420,
        defaultHeight: 318,
        supportsMultipleWindows: true
    )

    static let notes = HaloApplicationDescriptor(
        id: HaloAppID.notes,
        name: "Halo Notes",
        summary: "Capture a thought without leaving the room.",
        iconSystemName: "note.text",
        accent: .amber,
        category: .productivity,
        defaultWidth: 380,
        defaultHeight: 290,
        supportsMultipleWindows: true
    )

    static let photos = HaloApplicationDescriptor(
        id: HaloAppID.photos,
        name: "Halo Photos",
        summary: "A private window into your library.",
        iconSystemName: "photo.on.rectangle.angled",
        accent: .violet,
        category: .media,
        defaultWidth: 390,
        defaultHeight: 300,
        supportsMultipleWindows: false
    )

    static let calculator = HaloApplicationDescriptor(
        id: HaloAppID.calculator,
        name: "Calculator",
        summary: "Quick arithmetic on a spatial surface.",
        iconSystemName: "plus.forwardslash.minus",
        accent: .mint,
        category: .utility,
        defaultWidth: 320,
        defaultHeight: 318,
        supportsMultipleWindows: true
    )

    static let settings = HaloApplicationDescriptor(
        id: HaloAppID.settings,
        name: "Halo Settings",
        summary: "Tune your space while inside it.",
        iconSystemName: "gearshape",
        accent: .silver,
        category: .settings,
        defaultWidth: 360,
        defaultHeight: 300,
        supportsMultipleWindows: false
    )

    static let builtIns: [HaloApplicationDescriptor] = [
        .browser, .notes, .photos, .calculator, .settings
    ]
}

@MainActor
final class ApplicationCatalog: ObservableObject {
    @Published private(set) var webApplications: [WebApplication] = []

    private let store: WebApplicationStore

    init(store: WebApplicationStore = WebApplicationStore()) {
        self.store = store
        webApplications = store.load()
    }

    var builtInApplications: [HaloApplicationDescriptor] {
        HaloApplicationDescriptor.builtIns
    }

    var allApplications: [HaloApplicationDescriptor] {
        builtInApplications + webApplications.map(descriptor(for:))
    }

    var builtInCount: Int { HaloApplicationDescriptor.builtIns.count }

    func descriptor(for windowApplicationID: String) -> HaloApplicationDescriptor? {
        if let builtIn = HaloApplicationDescriptor.builtIns.first(where: { $0.id == windowApplicationID }) {
            return builtIn
        }
        if let web = webApplication(withApplicationID: windowApplicationID) {
            return descriptor(for: web)
        }
        return nil
    }

    func descriptor(for webApplication: WebApplication) -> HaloApplicationDescriptor {
        HaloApplicationDescriptor(
            id: HaloAppID.webApplicationID(from: webApplication.id),
            name: webApplication.name,
            summary: WebApplication.summaryText(for: webApplication.host),
            iconSystemName: webApplication.iconSystemName,
            accent: webApplication.accent,
            category: .web,
            defaultWidth: 420,
            defaultHeight: 320,
            supportsMultipleWindows: true,
            webURL: webApplication.url
        )
    }

    func webApplication(withApplicationID id: String) -> WebApplication? {
        guard HaloAppID.isWebApplication(id) else { return nil }
        return webApplications.first { HaloAppID.webApplicationID(from: $0.id) == id }
    }

    func search(_ query: String) -> [HaloApplicationDescriptor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return allApplications }
        return allApplications.filter {
            $0.name.lowercased().contains(trimmed)
                || $0.summary.lowercased().contains(trimmed)
                || $0.category.title.lowercased().contains(trimmed)
        }
    }

    @discardableResult
    func addWebApplication(name: String, urlString: String, iconSystemName: String, accent: HaloAccent) -> WebApplication? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedName.isEmpty,
            let url = HaloLinkParser.validatedWebAppURL(from: urlString)
        else { return nil }

        let app = WebApplication(
            name: trimmedName,
            urlString: url.absoluteString,
            iconSystemName: iconSystemName,
            accent: accent
        )
        webApplications.append(app)
        persist()
        return app
    }

    func deleteWebApplication(id: UUID) {
        webApplications.removeAll { $0.id == id }
        persist()
    }

    func updateWebApplication(_ app: WebApplication) {
        guard let index = webApplications.firstIndex(where: { $0.id == app.id }) else { return }
        webApplications[index] = app
        persist()
    }

    func deleteAllWebApplications() {
        webApplications.removeAll()
        persist()
    }

    private func persist() {
        do {
            try store.save(webApplications)
        } catch {
            HaloLog.error("Web app save failed: \(error.localizedDescription)", logger: HaloLog.persistence)
        }
    }
}

struct WebApplication: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var urlString: String
    var iconSystemName: String
    var accent: HaloAccent
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        iconSystemName: String = "globe",
        accent: HaloAccent = .ice,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.iconSystemName = iconSystemName
        self.accent = accent
        self.createdAt = createdAt
    }

    var url: URL? {
        URL(string: urlString)
    }

    var host: String {
        url?.host?.replacingOccurrences(of: "www.", with: "") ?? urlString
    }

    static func summaryText(for host: String) -> String {
        "Spatial web app · \(host)"
    }
}

final class WebApplicationStore {
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("HaloSpace", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("web-apps.json")
    }

    func load() -> [WebApplication] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let apps = try? JSONDecoder().decode([WebApplication].self, from: data)
        else { return [] }
        return apps
    }

    func save(_ apps: [WebApplication]) throws {
        do {
            let data = try JSONEncoder().encode(apps)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw HaloPersistenceError.writeFailed(error.localizedDescription)
        }
    }
}
