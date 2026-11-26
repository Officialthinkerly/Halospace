//
//  WindowPersistence.swift
//  HaloSpace V3
//

import Foundation

struct HaloWorkspaceSnapshot: Codable {
    var version: Int
    var savedAt: Date
    var windows: [HaloWindowModel]
    var focusedWindowID: UUID?

    init(version: Int = 1, savedAt: Date = Date(), windows: [HaloWindowModel], focusedWindowID: UUID?) {
        self.version = version
        self.savedAt = savedAt
        self.windows = windows
        self.focusedWindowID = focusedWindowID
    }
}

final class WorkspaceStore {
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("HaloSpace", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("workspace.json")
    }

    var hasStoredWorkspace: Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }

    func load() -> HaloWorkspaceSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(HaloWorkspaceSnapshot.self, from: data)
        } catch {
            HaloLog.error("Workspace decode failed: \(error.localizedDescription)", logger: HaloLog.persistence)
            return nil
        }
    }

    func save(_ snapshot: HaloWorkspaceSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw HaloPersistenceError.writeFailed(error.localizedDescription)
        }
    }

    func clear() {
        try? fileManager.removeItem(at: fileURL)
    }
}
