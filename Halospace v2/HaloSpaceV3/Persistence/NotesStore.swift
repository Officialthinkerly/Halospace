//
//  NotesStore.swift
//  HaloSpace V3
//

import Foundation

struct HaloNote: Identifiable, Codable, Equatable {
    let id: UUID
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), body: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var title: String {
        let firstLine = body
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firstLine.isEmpty ? "New Note" : String(firstLine.prefix(46))
    }

    var preview: String {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > 1 else { return "No additional text" }
        return lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var notes: [HaloNote] = []

    private let fileURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("HaloSpace", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("notes.json")
        load()
    }

    var sortedNotes: [HaloNote] {
        notes.sorted { $0.updatedAt > $1.updatedAt }
    }

    func note(id: UUID) -> HaloNote? {
        notes.first { $0.id == id }
    }

    @discardableResult
    func createNote(body: String = "") -> HaloNote {
        let note = HaloNote(body: body)
        notes.append(note)
        persist()
        return note
    }

    func updateNote(id: UUID, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].body = body
        notes[index].updatedAt = Date()
        persist()
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    func deleteAll() {
        notes.removeAll()
        persist()
    }

    func search(_ query: String) -> [HaloNote] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sortedNotes }
        return sortedNotes.filter {
            $0.body.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            seedWelcomeNote()
            return
        }
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([HaloNote].self, from: data)
        else {
            seedWelcomeNote()
            return
        }
        notes = decoded
    }

    private func seedWelcomeNote() {
        let body = """
        Welcome to HaloSpace.

        This window lives inside your spatial workspace. Try moving it with the title bar, resizing it from the lower-right corner, or opening another app from the dock.

        When hand tracking is available, pinch your thumb and index finger together and drag to move a focused window.

        Your notes stay on this iPhone.
        """
        notes = [HaloNote(body: body)]
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            HaloLog.error("Notes save failed: \(error.localizedDescription)", logger: HaloLog.persistence)
        }
    }
}
