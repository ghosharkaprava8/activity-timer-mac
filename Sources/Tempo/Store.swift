import Foundation
import Combine
import SwiftUI

final class Store: ObservableObject {
    @Published private(set) var data = AppData()

    private let fileURL: URL

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tempo", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("data.json")
        load()
        normalizeColors()
    }

    // MARK: - Persistence

    private func load() {
        guard let raw = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: raw) else { return }
        data = decoded
    }

    private func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let raw = try? enc.encode(data) {
            try? raw.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Tasks

    private func pickColor(_ used: Set<String>) -> String {
        PALETTE.first { !used.contains($0) } ?? PALETTE[used.count % PALETTE.count]
    }

    func addTask(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !data.tasks.contains(where: { $0.name == trimmed }) else { return }
        let color = pickColor(Set(data.tasks.map { $0.color }))
        data.tasks.append(TaskItem(name: trimmed, color: color))
        save()
    }

    func removeTask(_ name: String) {
        data.tasks.removeAll { $0.name == name }
        data.sessions.removeAll { $0.task == name }
        if data.active?.task == name { data.active = nil }
        save()
    }

    private func normalizeColors() {
        var used = Set<String>()
        var changed = false
        for i in data.tasks.indices {
            if data.tasks[i].color.isEmpty || used.contains(data.tasks[i].color) {
                let next = pickColor(used)
                if data.tasks[i].color != next { data.tasks[i].color = next; changed = true }
            }
            used.insert(data.tasks[i].color)
        }
        if changed { save() }
    }

    func color(for task: String) -> Color {
        Color(hex: data.tasks.first { $0.name == task }?.color ?? "#94a3b8")
    }

    // MARK: - Timer

    func start(_ task: String) {
        if data.active != nil { stop() }
        data.active = Active(task: task, start: Date().timeIntervalSince1970)
        save()
    }

    @discardableResult
    func stop(at end: Double? = nil) -> Bool {
        guard let active = data.active else { return false }
        let endTs = max(active.start, end ?? Date().timeIntervalSince1970)
        let s = Session(
            id: "\(Int(active.start * 1000))-\(Int.random(in: 0..<1_000_000))",
            task: active.task, start: active.start, end: endTs
        )
        data.sessions.append(s)
        data.active = nil
        save()
        return true
    }

    func resetToday(_ task: String) {
        let today = Self.startOfToday()
        data.sessions.removeAll { $0.task == task && $0.end >= today }
        if data.active?.task == task { data.active = nil }
        save()
    }

    func deleteSession(_ id: String) {
        data.sessions.removeAll { $0.id == id }
        save()
    }

    // MARK: - Aggregation

    static func startOfToday() -> Double {
        Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    func todayByTask() -> [(task: String, seconds: Double)] {
        let today = Self.startOfToday()
        var map: [String: Double] = [:]
        for s in data.sessions where s.end >= today {
            map[s.task, default: 0] += s.duration
        }
        return map.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func todaySeconds(for task: String) -> Double {
        let today = Self.startOfToday()
        return data.sessions
            .filter { $0.task == task && $0.end >= today }
            .reduce(0) { $0 + $1.duration }
    }
}
