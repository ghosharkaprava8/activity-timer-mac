import Foundation

enum Fmt {
    static func clock(_ seconds: Double) -> String {
        let t = Int(max(0, seconds))
        return String(format: "%02d:%02d:%02d", t / 3600, (t % 3600) / 60, t % 60)
    }

    // Compact form for the menu-bar title, e.g. "1:24:36".
    static func barClock(_ seconds: Double) -> String {
        let t = Int(max(0, seconds))
        return String(format: "%d:%02d:%02d", t / 3600, (t % 3600) / 60, t % 60)
    }

    static func hours(_ seconds: Double) -> String {
        String(format: "%.2f h", seconds / 3600)
    }

    static func hours1(_ seconds: Double) -> String {
        String(format: "%.1f h", seconds / 3600)
    }

    static func dur(_ seconds: Double) -> String {
        let m = Int((seconds / 60).rounded())
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }
}
