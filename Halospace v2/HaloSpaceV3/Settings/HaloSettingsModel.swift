//
//  HaloSettingsModel.swift
//  HaloSpace V3
//

import Combine
import Foundation
import SwiftUI

enum HaloLaunchMode: String, Codable, CaseIterable, Identifiable {
    case ar
    case vr
    case ultraFast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ar: return "AR"
        case .vr: return "VR"
        case .ultraFast: return "Ultra Fast"
        }
    }

    var compactTitle: String {
        switch self {
        case .ar: return "AR Mode"
        case .vr: return "VR Mode"
        case .ultraFast: return "Ultra Fast"
        }
    }

    var subtitle: String {
        switch self {
        case .ar: return "Handheld spatial workspace"
        case .vr: return "Stereo preview for headsets"
        case .ultraFast: return "Reduced processing, best battery"
        }
    }

    var systemImage: String {
        switch self {
        case .ar: return "viewfinder"
        case .vr: return "rectangle.split.2x1"
        case .ultraFast: return "bolt"
        }
    }
}

enum HaloEnvironmentStyle: String, Codable, CaseIterable, Identifiable {
    case midnight
    case graphite
    case dusk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .dusk: return "Dusk"
        }
    }

    var detail: String {
        switch self {
        case .midnight: return "Cool deep-space ambience"
        case .graphite: return "Neutral, low-glare workspace"
        case .dusk: return "Soft violet evening light"
        }
    }
}

enum HaloWindowPlacement: String, Codable, CaseIterable, Identifiable {
    case arc
    case centered
    case layered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arc: return "Floating Arc"
        case .centered: return "Centered"
        case .layered: return "Layered Depth"
        }
    }

    var detail: String {
        switch self {
        case .arc: return "Windows curve gently around you"
        case .centered: return "New windows open directly ahead"
        case .layered: return "New windows stagger near and far"
        }
    }
}

enum HaloWindowTint: String, Codable, CaseIterable, Identifiable {
    case graphite
    case frost
    case slate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphite: return "Graphite"
        case .frost: return "Frost"
        case .slate: return "Slate"
        }
    }

    var tintColor: Color {
        switch self {
        case .graphite: return Color(red: 0.10, green: 0.12, blue: 0.15)
        case .frost: return Color(red: 0.15, green: 0.18, blue: 0.22)
        case .slate: return Color(red: 0.08, green: 0.11, blue: 0.14)
        }
    }
}

enum HaloSearchEngine: String, Codable, CaseIterable, Identifiable {
    case duckDuckGo
    case google
    case bing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .duckDuckGo: return "DuckDuckGo"
        case .google: return "Google"
        case .bing: return "Bing"
        }
    }

    var searchURL: (String) -> URL? {
        { query in
            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            switch self {
            case .duckDuckGo: return URL(string: "https://duckduckgo.com/?q=\(encoded)")
            case .google: return URL(string: "https://www.google.com/search?q=\(encoded)")
            case .bing: return URL(string: "https://www.bing.com/search?q=\(encoded)")
            }
        }
    }
}

enum HaloHandTrackingRate: String, Codable, CaseIterable, Identifiable {
    case efficient
    case balanced
    case responsive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .efficient: return "Efficient"
        case .balanced: return "Balanced"
        case .responsive: return "Responsive"
        }
    }

    var detail: String {
        switch self {
        case .efficient: return "About 8 analyses per second"
        case .balanced: return "About 15 analyses per second"
        case .responsive: return "About 24 analyses per second"
        }
    }

    var framesPerSecond: Double {
        switch self {
        case .efficient: return 8
        case .balanced: return 15
        case .responsive: return 24
        }
    }
}

struct HaloSettingsSnapshot: Codable, Equatable {
    var schemaVersion: Int = 1
    var defaultLaunchMode: HaloLaunchMode = .ar
    var environmentStyle: HaloEnvironmentStyle = .midnight
    var windowPlacement: HaloWindowPlacement = .arc
    var windowScale: Double = 1.0
    var windowTint: HaloWindowTint = .graphite
    var uiTransparency: Double = 0.82
    var showWindowLabels: Bool = true
    var gesturesEnabled: Bool = true
    var handTrackingEnabled: Bool = true
    var handTrackingRate: HaloHandTrackingRate = .balanced
    var pinchSensitivity: Double = 0.62
    var dragSensitivity: Double = 1.0
    var hapticsEnabled: Bool = true
    var performanceMode: Bool = false
    var planeDetectionEnabled: Bool = true
    var searchEngine: HaloSearchEngine = .duckDuckGo
    var debugLoggingEnabled: Bool = false
    var showDiagnosticsOverlay: Bool = false
    var developerModeUnlocked: Bool = false
    var onboardingCompleted: Bool = false

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case defaultLaunchMode
        case environmentStyle
        case windowPlacement
        case windowScale
        case windowTint
        case uiTransparency
        case showWindowLabels
        case gesturesEnabled
        case handTrackingEnabled
        case handTrackingRate
        case pinchSensitivity
        case dragSensitivity
        case hapticsEnabled
        case performanceMode
        case planeDetectionEnabled
        case searchEngine
        case debugLoggingEnabled
        case showDiagnosticsOverlay
        case developerModeUnlocked
        case onboardingCompleted
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        defaultLaunchMode = try container.decodeIfPresent(HaloLaunchMode.self, forKey: .defaultLaunchMode) ?? .ar
        environmentStyle = try container.decodeIfPresent(HaloEnvironmentStyle.self, forKey: .environmentStyle) ?? .midnight
        windowPlacement = try container.decodeIfPresent(HaloWindowPlacement.self, forKey: .windowPlacement) ?? .arc
        windowScale = try container.decodeIfPresent(Double.self, forKey: .windowScale) ?? 1.0
        windowTint = try container.decodeIfPresent(HaloWindowTint.self, forKey: .windowTint) ?? .graphite
        uiTransparency = try container.decodeIfPresent(Double.self, forKey: .uiTransparency) ?? 0.82
        showWindowLabels = try container.decodeIfPresent(Bool.self, forKey: .showWindowLabels) ?? true
        gesturesEnabled = try container.decodeIfPresent(Bool.self, forKey: .gesturesEnabled) ?? true
        handTrackingEnabled = try container.decodeIfPresent(Bool.self, forKey: .handTrackingEnabled) ?? true
        handTrackingRate = try container.decodeIfPresent(HaloHandTrackingRate.self, forKey: .handTrackingRate) ?? .balanced
        pinchSensitivity = try container.decodeIfPresent(Double.self, forKey: .pinchSensitivity) ?? 0.62
        dragSensitivity = try container.decodeIfPresent(Double.self, forKey: .dragSensitivity) ?? 1.0
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        performanceMode = try container.decodeIfPresent(Bool.self, forKey: .performanceMode) ?? false
        planeDetectionEnabled = try container.decodeIfPresent(Bool.self, forKey: .planeDetectionEnabled) ?? true
        searchEngine = try container.decodeIfPresent(HaloSearchEngine.self, forKey: .searchEngine) ?? .duckDuckGo
        debugLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .debugLoggingEnabled) ?? false
        showDiagnosticsOverlay = try container.decodeIfPresent(Bool.self, forKey: .showDiagnosticsOverlay) ?? false
        developerModeUnlocked = try container.decodeIfPresent(Bool.self, forKey: .developerModeUnlocked) ?? false
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
    }
}

@MainActor
final class HaloSettingsModel: ObservableObject {
    @Published var defaultLaunchMode: HaloLaunchMode
    @Published var environmentStyle: HaloEnvironmentStyle
    @Published var windowPlacement: HaloWindowPlacement
    @Published var windowScale: Double
    @Published var windowTint: HaloWindowTint
    @Published var uiTransparency: Double
    @Published var showWindowLabels: Bool
    @Published var gesturesEnabled: Bool
    @Published var handTrackingEnabled: Bool
    @Published var handTrackingRate: HaloHandTrackingRate
    @Published var pinchSensitivity: Double
    @Published var dragSensitivity: Double
    @Published var hapticsEnabled: Bool
    @Published var performanceMode: Bool
    @Published var planeDetectionEnabled: Bool
    @Published var searchEngine: HaloSearchEngine
    @Published var debugLoggingEnabled: Bool
    @Published var showDiagnosticsOverlay: Bool
    @Published var developerModeUnlocked: Bool
    @Published var onboardingCompleted: Bool

    private let store: SettingsStore
    private var saveCancellable: AnyCancellable?
    private var isApplyingSnapshot = false

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        let snapshot = store.load()
        defaultLaunchMode = snapshot.defaultLaunchMode
        environmentStyle = snapshot.environmentStyle
        windowPlacement = snapshot.windowPlacement
        windowScale = snapshot.windowScale
        windowTint = snapshot.windowTint
        uiTransparency = snapshot.uiTransparency
        showWindowLabels = snapshot.showWindowLabels
        gesturesEnabled = snapshot.gesturesEnabled
        handTrackingEnabled = snapshot.handTrackingEnabled
        handTrackingRate = snapshot.handTrackingRate
        pinchSensitivity = snapshot.pinchSensitivity
        dragSensitivity = snapshot.dragSensitivity
        hapticsEnabled = snapshot.hapticsEnabled
        performanceMode = snapshot.performanceMode
        planeDetectionEnabled = snapshot.planeDetectionEnabled
        searchEngine = snapshot.searchEngine
        debugLoggingEnabled = snapshot.debugLoggingEnabled
        showDiagnosticsOverlay = snapshot.showDiagnosticsOverlay
        developerModeUnlocked = snapshot.developerModeUnlocked
        onboardingCompleted = snapshot.onboardingCompleted
        HaloLog.verboseEnabled = snapshot.debugLoggingEnabled

        saveCancellable = objectWillChange
            .debounce(for: .milliseconds(220), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }

    var snapshot: HaloSettingsSnapshot {
        HaloSettingsSnapshot(
            schemaVersion: 1,
            defaultLaunchMode: defaultLaunchMode,
            environmentStyle: environmentStyle,
            windowPlacement: windowPlacement,
            windowScale: windowScale,
            windowTint: windowTint,
            uiTransparency: uiTransparency,
            showWindowLabels: showWindowLabels,
            gesturesEnabled: gesturesEnabled,
            handTrackingEnabled: handTrackingEnabled,
            handTrackingRate: handTrackingRate,
            pinchSensitivity: pinchSensitivity,
            dragSensitivity: dragSensitivity,
            hapticsEnabled: hapticsEnabled,
            performanceMode: performanceMode,
            planeDetectionEnabled: planeDetectionEnabled,
            searchEngine: searchEngine,
            debugLoggingEnabled: debugLoggingEnabled,
            showDiagnosticsOverlay: showDiagnosticsOverlay,
            developerModeUnlocked: developerModeUnlocked,
            onboardingCompleted: onboardingCompleted
        )
    }

    func selectLaunchMode(_ mode: HaloLaunchMode) {
        defaultLaunchMode = mode
        performanceMode = mode == .ultraFast
    }

    func setDebugLogging(_ enabled: Bool) {
        debugLoggingEnabled = enabled
        HaloLog.verboseEnabled = enabled
    }

    func save() {
        guard !isApplyingSnapshot else { return }
        do {
            try store.save(snapshot)
        } catch {
            HaloLog.error("Failed to save settings: \(error.localizedDescription)")
        }
    }

    func resetToDefaults() {
        var defaults = HaloSettingsSnapshot()
        defaults.onboardingCompleted = onboardingCompleted
        apply(defaults)
    }

    private func apply(_ snapshot: HaloSettingsSnapshot) {
        isApplyingSnapshot = true
        defaultLaunchMode = snapshot.defaultLaunchMode
        environmentStyle = snapshot.environmentStyle
        windowPlacement = snapshot.windowPlacement
        windowScale = snapshot.windowScale
        windowTint = snapshot.windowTint
        uiTransparency = snapshot.uiTransparency
        showWindowLabels = snapshot.showWindowLabels
        gesturesEnabled = snapshot.gesturesEnabled
        handTrackingEnabled = snapshot.handTrackingEnabled
        handTrackingRate = snapshot.handTrackingRate
        pinchSensitivity = snapshot.pinchSensitivity
        dragSensitivity = snapshot.dragSensitivity
        hapticsEnabled = snapshot.hapticsEnabled
        performanceMode = snapshot.performanceMode
        planeDetectionEnabled = snapshot.planeDetectionEnabled
        searchEngine = snapshot.searchEngine
        debugLoggingEnabled = snapshot.debugLoggingEnabled
        showDiagnosticsOverlay = snapshot.showDiagnosticsOverlay
        developerModeUnlocked = snapshot.developerModeUnlocked
        onboardingCompleted = snapshot.onboardingCompleted
        isApplyingSnapshot = false
        save()
    }
}

struct SettingsStore {
    private let defaults: UserDefaults
    private let key = "halospace.settings.v3"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> HaloSettingsSnapshot {
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(HaloSettingsSnapshot.self, from: data)
        else {
            return HaloSettingsSnapshot()
        }
        return snapshot
    }

    func save(_ snapshot: HaloSettingsSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            let data = try encoder.encode(snapshot)
            defaults.set(data, forKey: key)
        } catch {
            throw HaloPersistenceError.encodingFailed(error.localizedDescription)
        }
    }
}

private extension HaloSettingsSnapshot {
    init(
        schemaVersion: Int,
        defaultLaunchMode: HaloLaunchMode,
        environmentStyle: HaloEnvironmentStyle,
        windowPlacement: HaloWindowPlacement,
        windowScale: Double,
        windowTint: HaloWindowTint,
        uiTransparency: Double,
        showWindowLabels: Bool,
        gesturesEnabled: Bool,
        handTrackingEnabled: Bool,
        handTrackingRate: HaloHandTrackingRate,
        pinchSensitivity: Double,
        dragSensitivity: Double,
        hapticsEnabled: Bool,
        performanceMode: Bool,
        planeDetectionEnabled: Bool,
        searchEngine: HaloSearchEngine,
        debugLoggingEnabled: Bool,
        showDiagnosticsOverlay: Bool,
        developerModeUnlocked: Bool,
        onboardingCompleted: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.defaultLaunchMode = defaultLaunchMode
        self.environmentStyle = environmentStyle
        self.windowPlacement = windowPlacement
        self.windowScale = windowScale
        self.windowTint = windowTint
        self.uiTransparency = uiTransparency
        self.showWindowLabels = showWindowLabels
        self.gesturesEnabled = gesturesEnabled
        self.handTrackingEnabled = handTrackingEnabled
        self.handTrackingRate = handTrackingRate
        self.pinchSensitivity = pinchSensitivity
        self.dragSensitivity = dragSensitivity
        self.hapticsEnabled = hapticsEnabled
        self.performanceMode = performanceMode
        self.planeDetectionEnabled = planeDetectionEnabled
        self.searchEngine = searchEngine
        self.debugLoggingEnabled = debugLoggingEnabled
        self.showDiagnosticsOverlay = showDiagnosticsOverlay
        self.developerModeUnlocked = developerModeUnlocked
        self.onboardingCompleted = onboardingCompleted
    }
}
