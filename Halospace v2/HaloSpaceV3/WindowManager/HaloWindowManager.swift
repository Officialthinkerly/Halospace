//
//  HaloWindowManager.swift
//  HaloSpace V3
//

import CoreGraphics
import Foundation
import SwiftUI

enum HaloAppID {
    static let browser = "halo.browser"
    static let notes = "halo.notes"
    static let photos = "halo.photos"
    static let calculator = "halo.calculator"
    static let settings = "halo.settings"
    static let webPrefix = "halo.web."

    static func isWebApplication(_ id: String) -> Bool {
        id.hasPrefix(webPrefix)
    }

    static func webApplicationID(from storeID: UUID) -> String {
        webPrefix + storeID.uuidString
    }
}

@MainActor
final class HaloWindowManager: ObservableObject {
    @Published private(set) var windows: [HaloWindowModel] = []
    @Published private(set) var focusedWindowID: UUID?
    @Published private(set) var lastErrorMessage: String?

    private let settings: HaloSettingsModel
    private let store: WorkspaceStore
    private var saveTask: Task<Void, Never>?
    private var seededThisSession = false

    init(settings: HaloSettingsModel, store: WorkspaceStore = WorkspaceStore()) {
        self.settings = settings
        self.store = store
        loadPersistedWorkspace()
    }

    deinit {
        saveTask?.cancel()
    }

    var visibleWindows: [HaloWindowModel] {
        windows.filter { !$0.isMinimized }.sorted { $0.zIndex < $1.zIndex }
    }

    var minimizedWindows: [HaloWindowModel] {
        windows.filter(\.isMinimized).sorted { $0.createdAt < $1.createdAt }
    }

    var focusedWindow: HaloWindowModel? {
        guard let id = focusedWindowID else { return nil }
        return windows.first { $0.id == id }
    }

    var canOpenMoreWindows: Bool {
        windows.count < HaloWindowMetrics.maxWindows
    }

    func prepareForSpatialEntry() {
        if windows.isEmpty {
            seedWelcomeWorkspaceIfNeeded()
        }
        if focusedWindowID == nil || windows.first(where: { $0.id == focusedWindowID }) == nil {
            focusedWindowID = windows
                .filter { !$0.isMinimized }
                .max { $0.zIndex < $1.zIndex }?
                .id
        }
        arrangeInvalidWindows()
        scheduleSave()
    }

    @discardableResult
    func open(
        applicationID: String,
        title: String,
        size: CGSize = HaloWindowMetrics.defaultSize,
        payload: [String: String] = [:],
        preferFocusedPlacement: Bool = false
    ) -> UUID? {
        guard canOpenMoreWindows else {
            lastErrorMessage = "HaloSpace can hold up to \(HaloWindowMetrics.maxWindows) open windows. Close one to make room."
            return nil
        }

        let clampedSize = HaloWindowMetrics.clamped(size)
        let position = placementPosition(forNewWindow: preferFocusedPlacement)
        let nextZ = (windows.map(\.zIndex).max() ?? 0) + 1
        let model = HaloWindowModel(
            applicationID: applicationID,
            title: title,
            localPosition: position,
            localYaw: 0,
            logicalSize: HaloWindowSize(clampedSize),
            isMinimized: false,
            zIndex: nextZ,
            payload: payload
        )
        windows.append(model)
        focusedWindowID = model.id
        lastErrorMessage = nil
        scheduleSave()
        HaloLog.info("Opened window \(title) (\(applicationID))", logger: HaloLog.windows)
        return model.id
    }

    func close(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        let nextFocus = HaloWindowOrdering.nextFocus(after: id, windows: windows)
        windows.remove(at: index)
        if focusedWindowID == id {
            focusedWindowID = nextFocus
        }
        scheduleSave()
    }

    func closeAll() {
        windows.removeAll()
        focusedWindowID = nil
        scheduleSave()
    }

    func focus(_ id: UUID, raise: Bool = true) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        if windows[index].isMinimized {
            windows[index].isMinimized = false
        }
        guard raise else {
            focusedWindowID = id
            return
        }
        if focusedWindowID == id && windows[index].zIndex == (windows.map(\.zIndex).max() ?? 0) {
            return
        }
        let nextZ = (windows.map(\.zIndex).max() ?? 0) + 1
        windows[index].zIndex = nextZ
        focusedWindowID = id
        scheduleSave()
    }

    func unfocus() {
        focusedWindowID = nil
        scheduleSave()
    }

    func minimize(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].isMinimized = true
        if focusedWindowID == id {
            focusedWindowID = HaloWindowOrdering.nextFocus(after: id, windows: windows.filter { !$0.isMinimized })
        }
        scheduleSave()
    }

    func restore(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].isMinimized = false
        focus(id)
        scheduleSave()
    }

    func toggleMinimized(_ id: UUID) {
        guard let window = windows.first(where: { $0.id == id }) else { return }
        if window.isMinimized {
            restore(id)
        } else {
            minimize(id)
        }
    }

    func move(_ id: UUID, localDelta: SIMD3<Float>) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        var target = windows[index].localPosition.simdValue + localDelta
        target.x = min(max(target.x, HaloWindowMetrics.horizontalRange.lowerBound), HaloWindowMetrics.horizontalRange.upperBound)
        target.y = min(max(target.y, HaloWindowMetrics.verticalRange.lowerBound), HaloWindowMetrics.verticalRange.upperBound)
        target.z = min(max(target.z, HaloWindowMetrics.depthRange.lowerBound), HaloWindowMetrics.depthRange.upperBound)
        windows[index].localPosition = HaloVector3(target)
        scheduleSave()
    }

    func setPosition(_ id: UUID, position: HaloVector3) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].localPosition = HaloVector3(
            x: min(max(position.x, HaloWindowMetrics.horizontalRange.lowerBound), HaloWindowMetrics.horizontalRange.upperBound),
            y: min(max(position.y, HaloWindowMetrics.verticalRange.lowerBound), HaloWindowMetrics.verticalRange.upperBound),
            z: min(max(position.z, HaloWindowMetrics.depthRange.lowerBound), HaloWindowMetrics.depthRange.upperBound)
        )
        scheduleSave()
    }

    func resize(_ id: UUID, to size: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].logicalSize = HaloWindowSize(HaloWindowMetrics.clamped(size))
        scheduleSave()
    }

    func setTitle(_ id: UUID, title: String) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, windows[index].title != trimmed else { return }
        windows[index].title = trimmed
        scheduleSave()
    }

    func updatePayload(_ id: UUID, key: String, value: String?) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        if let value {
            guard windows[index].payload[key] != value else { return }
            windows[index].payload[key] = value
        } else {
            guard windows[index].payload[key] != nil else { return }
            windows[index].payload.removeValue(forKey: key)
        }
        scheduleSave()
    }

    func payloadValue(windowID: UUID, key: String) -> String? {
        windows.first(where: { $0.id == windowID })?.payload[key]
    }

    func resetWorkspace() {
        windows.removeAll()
        focusedWindowID = nil
        store.clear()
        seededThisSession = false
        seedWelcomeWorkspaceIfNeeded()
        scheduleSave()
    }

    func tidyWorkspace() {
        let visible = visibleWindows
        guard !visible.isEmpty else { return }
        let spacing: Float = visible.count > 1 ? 0.72 : 0
        let startX = -Float(visible.count - 1) * spacing / 2
        for (offset, window) in visible.enumerated() {
            guard let index = windows.firstIndex(where: { $0.id == window.id }) else { continue }
            windows[index].localPosition = HaloVector3(
                x: startX + Float(offset) * spacing,
                y: 0.02,
                z: 0.02
            )
            windows[index].localYaw = 0
        }
        focusedWindowID = visible.last?.id
        scheduleSave()
    }

    func clearError() {
        lastErrorMessage = nil
    }

    func flushPersistence() {
        saveTask?.cancel()
        persistNow()
    }

    // MARK: - Placement

    private func placementPosition(forNewWindow preferFocusedPlacement: Bool) -> HaloVector3 {
        let index = windows.count
        switch settings.windowPlacement {
        case .centered:
            return HaloVector3(x: 0, y: 0.03, z: 0.02 + Float(index % 3) * -0.12)
        case .arc:
            let slots: [HaloVector3] = [
                HaloVector3(x: 0, y: 0.02, z: 0.02),
                HaloVector3(x: 0.54, y: 0.01, z: -0.10),
                HaloVector3(x: -0.54, y: 0.01, z: -0.10),
                HaloVector3(x: 0.24, y: -0.04, z: 0.12),
                HaloVector3(x: -0.24, y: -0.04, z: 0.12),
                HaloVector3(x: 0, y: 0.05, z: -0.24)
            ]
            return slots[index % slots.count]
        case .layered:
            let x: Float = index % 2 == 0 ? -0.30 : 0.30
            let z = 0.06 - Float(index % 4) * 0.16
            return HaloVector3(x: x, y: 0.02 + Float(index % 2) * -0.06, z: z)
        }
    }

    private func seedWelcomeWorkspaceIfNeeded() {
        guard !seededThisSession else { return }
        seededThisSession = true
        guard !store.hasStoredWorkspace else { return }
        guard windows.isEmpty else { return }

        windows.append(
            HaloWindowModel(
                applicationID: HaloAppID.notes,
                title: "Halo Notes",
                localPosition: HaloVector3(x: -0.44, y: 0.02, z: 0.04),
                logicalSize: HaloWindowSize(width: 380, height: 280),
                zIndex: 0
            )
        )
        windows.append(
            HaloWindowModel(
                applicationID: HaloAppID.calculator,
                title: "Calculator",
                localPosition: HaloVector3(x: 0.48, y: -0.02, z: -0.14),
                logicalSize: HaloWindowSize(width: 320, height: 300),
                zIndex: 1
            )
        )
        focusedWindowID = windows.last?.id
    }

    private func loadPersistedWorkspace() {
        guard let snapshot = store.load() else { return }
        var seen = Set<UUID>()
        let restored = snapshot.windows
            .filter { seen.insert($0.id).inserted }
            .prefix(HaloWindowMetrics.maxWindows)
            .map { window -> HaloWindowModel in
                var clean = window
                clean.logicalSize = HaloWindowSize(
                    HaloWindowMetrics.clamped(window.logicalSize.cgSize)
                )
                clean.localPosition = HaloVector3(
                    x: min(max(clean.localPosition.x, HaloWindowMetrics.horizontalRange.lowerBound), HaloWindowMetrics.horizontalRange.upperBound),
                    y: min(max(clean.localPosition.y, HaloWindowMetrics.verticalRange.lowerBound), HaloWindowMetrics.verticalRange.upperBound),
                    z: min(max(clean.localPosition.z, HaloWindowMetrics.depthRange.lowerBound), HaloWindowMetrics.depthRange.upperBound)
                )
                return clean
            }
        windows = Array(restored)
        if let storedFocus = snapshot.focusedWindowID, windows.contains(where: { $0.id == storedFocus }) {
            focusedWindowID = storedFocus
        } else {
            focusedWindowID = windows.max { $0.zIndex < $1.zIndex }?.id
        }
        seededThisSession = true
        HaloLog.info("Restored \(windows.count) spatial windows", logger: HaloLog.persistence)
    }

    private func arrangeInvalidWindows() {
        for index in windows.indices {
            windows[index].logicalSize = HaloWindowSize(
                HaloWindowMetrics.clamped(windows[index].logicalSize.cgSize)
            )
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.persistNow()
            }
        }
    }

    private func persistNow() {
        let snapshot = HaloWorkspaceSnapshot(
            windows: windows,
            focusedWindowID: focusedWindowID
        )
        do {
            try store.save(snapshot)
        } catch {
            HaloLog.error("Workspace save failed: \(error.localizedDescription)", logger: HaloLog.persistence)
        }
    }
}
