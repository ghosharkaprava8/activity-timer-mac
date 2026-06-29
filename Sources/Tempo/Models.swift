import Foundation

// Time is stored as seconds since the Unix epoch (Date.timeIntervalSince1970).

struct TaskItem: Codable, Identifiable, Hashable {
    var name: String
    var color: String
    var id: String { name }
}

struct Session: Codable, Identifiable {
    var id: String
    var task: String
    var start: Double
    var end: Double
    var duration: Double { max(0, end - start) }
}

struct Active: Codable {
    var task: String
    var start: Double
}

struct AppData: Codable {
    var tasks: [TaskItem] = []
    var active: Active? = nil
    var sessions: [Session] = []
}

let PALETTE = [
    "#6366f1", // indigo
    "#16a34a", // green
    "#f59e0b", // amber
    "#ec4899", // pink
    "#06b6d4", // cyan
    "#8b5cf6", // violet
    "#ef4444", // red
    "#14b8a6", // teal
]
