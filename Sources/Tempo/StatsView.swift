import SwiftUI

struct StatsView: View {
    @ObservedObject var store: Store
    @State private var weekOffset = 0

    private let cal = Calendar.current
    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 9) {
                    Image(systemName: "stopwatch.fill").foregroundStyle(Color(hex: "#6366f1"))
                    Text("Tempo").font(.system(size: 20, weight: .semibold))
                }

                kpis
                chartCard
                HStack(alignment: .top, spacing: 16) {
                    breakdownCard
                    sessionsCard
                }
            }
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 560)
    }

    // MARK: - Week helpers

    private func startOfWeek(offset: Int) -> Date {
        let today = cal.startOfDay(for: Date())
        let weekday = (cal.component(.weekday, from: today) + 5) % 7 // Mon = 0
        let monday = cal.date(byAdding: .day, value: -weekday, to: today)!
        return cal.date(byAdding: .day, value: offset * 7, to: monday)!
    }

    private var weekSessions: [Session] {
        let start = startOfWeek(offset: weekOffset).timeIntervalSince1970
        let end = start + 7 * 86400
        return store.data.sessions.filter { $0.end >= start && $0.end < end }
    }

    private func perDay() -> [Double] {
        let start = startOfWeek(offset: weekOffset)
        var arr = [Double](repeating: 0, count: 7)
        for s in weekSessions {
            let day = cal.startOfDay(for: Date(timeIntervalSince1970: s.end))
            let idx = cal.dateComponents([.day], from: start, to: day).day ?? -1
            if idx >= 0 && idx < 7 { arr[idx] += s.duration }
        }
        return arr
    }

    // MARK: - Sections

    private var kpis: some View {
        let today = store.todayByTask().reduce(0) { $0 + $1.seconds }
        let week = weekSessions.reduce(0) { $0 + $1.duration }
        let activeDays = Set(weekSessions.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0.end)) }).count
        let avg = activeDays > 0 ? week / Double(activeDays) : 0
        return HStack(spacing: 14) {
            kpi("TODAY", Fmt.hours1(today))
            kpi("THIS WEEK", Fmt.hours1(week))
            kpi("DAILY AVG", Fmt.hours1(avg))
            kpi("STREAK", "\(streak()) d")
        }
    }

    private func kpi(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 11, weight: .semibold)).tracking(0.5)
                .foregroundStyle(.tertiary)
            Text(value).font(.system(size: 26, weight: .semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    private func streak() -> Int {
        let days = Set(store.data.sessions.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0.end)) })
        var count = 0
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
        while days.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    private var chartCard: some View {
        let data = perDay()
        let maxV = max(data.max() ?? 1, 1)
        let start = startOfWeek(offset: weekOffset)
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        let label = "\(fmt.string(from: start)) – \(fmt.string(from: cal.date(byAdding: .day, value: 6, to: start)!))"
        let todayStart = cal.startOfDay(for: Date())
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("HOURS PER DAY").font(.system(size: 13, weight: .semibold)).tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                Text(label).font(.system(size: 13, weight: .medium)).frame(width: 150)
                Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain).disabled(weekOffset >= 0)
            }
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0..<7, id: \.self) { i in
                    let dayDate = cal.date(byAdding: .day, value: i, to: start)!
                    let isToday = cal.isDate(dayDate, inSameDayAs: todayStart)
                    VStack(spacing: 8) {
                        Text(data[i] > 0 ? Fmt.hours1(data[i]).replacingOccurrences(of: " h", with: "") : "")
                            .font(.system(size: 12)).foregroundStyle(.secondary).frame(height: 15)
                        GeometryReader { geo in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isToday ? Color(hex: "#16a34a") : Color(hex: "#6366f1"))
                                    .frame(height: max(3, geo.size.height * (data[i] / maxV)))
                            }
                        }
                        Text(dayNames[i]).font(.system(size: 12)).foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .background(card)
    }

    private var breakdownCard: some View {
        var map: [String: Double] = [:]
        for s in weekSessions { map[s.task, default: 0] += s.duration }
        let entries = map.sorted { $0.value > $1.value }
        let maxV = entries.first?.value ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            Text("BY TASK").font(.system(size: 13, weight: .semibold)).tracking(0.6)
                .foregroundStyle(.tertiary)
            if entries.isEmpty {
                Text("No sessions this week.").font(.system(size: 13)).italic().foregroundStyle(.tertiary)
            } else {
                ForEach(entries, id: \.key) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Circle().fill(store.color(for: e.key)).frame(width: 9, height: 9)
                            Text(e.key).font(.system(size: 13))
                            Spacer()
                            Text(Fmt.hours(e.value)).font(.system(size: 13, weight: .medium)).monospacedDigit()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.07))
                                RoundedRectangle(cornerRadius: 5).fill(store.color(for: e.key))
                                    .frame(width: geo.size.width * (e.value / maxV))
                            }
                        }.frame(height: 9)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(card)
    }

    private var sessionsCard: some View {
        let sorted = weekSessions.sorted { $0.start > $1.start }
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        let tfmt = DateFormatter(); tfmt.dateFormat = "HH:mm"
        return VStack(alignment: .leading, spacing: 12) {
            Text("SESSIONS").font(.system(size: 13, weight: .semibold)).tracking(0.6)
                .foregroundStyle(.tertiary)
            if sorted.isEmpty {
                Text("No sessions this week.").font(.system(size: 13)).italic().foregroundStyle(.tertiary)
            } else {
                ForEach(sorted) { s in
                    HStack(spacing: 8) {
                        Text(fmt.string(from: Date(timeIntervalSince1970: s.start)))
                            .font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 52, alignment: .leading)
                        Circle().fill(store.color(for: s.task)).frame(width: 8, height: 8)
                        Text(s.task).font(.system(size: 13))
                        Spacer()
                        Text(Fmt.dur(s.duration)).font(.system(size: 13)).foregroundStyle(.secondary)
                        Button { store.deleteSession(s.id) } label: {
                            Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(.tertiary)
                        }.buttonStyle(.plain)
                    }
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(card)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08)))
    }
}
