import SwiftUI

struct MenuView: View {
    @ObservedObject var store: Store
    var openStats: () -> Void
    var quit: () -> Void

    @State private var newTask = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let active = store.data.active {
                activeCard(active)
            } else {
                Text("Pick a task to start the clock.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 2)
            }

            Text("TASKS")
                .font(.system(size: 11, weight: .semibold)).tracking(0.6)
                .foregroundStyle(.tertiary)

            VStack(spacing: 7) {
                if store.data.tasks.isEmpty {
                    Text("No tasks yet — add one below.")
                        .font(.system(size: 13)).italic()
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(store.data.tasks) { task in
                        taskRow(task)
                    }
                }
            }

            addRow

            Divider()
            todaySection
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Image(systemName: "stopwatch.fill").foregroundStyle(Color(hex: "#6366f1"))
            Text("Tempo").font(.system(size: 15, weight: .semibold))
            Spacer()
            Button(action: openStats) {
                Image(systemName: "chart.bar.fill").foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("Open stats")
            Button(action: quit) {
                Image(systemName: "power").foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("Quit Tempo")
        }
    }

    private func activeCard(_ active: Active) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                Circle().fill(Color(hex: "#16a34a")).frame(width: 9, height: 9)
                Text(active.task).font(.system(size: 14, weight: .semibold))
            }
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(Fmt.clock(Date().timeIntervalSince1970 - active.start))
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            Button(action: { store.stop() }) {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .background(Color(hex: "#ef4444"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .padding(14)
        .background(Color(hex: "#16a34a").opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func taskRow(_ task: TaskItem) -> some View {
        let running = store.data.active?.task == task.name
        let today = store.todaySeconds(for: task.name)
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: task.color)).frame(width: 10, height: 10)
            Text(task.name).font(.system(size: 14, weight: .medium))
            Spacer()
            if running {
                Text("Running…").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#16a34a"))
            } else {
                if today > 0 {
                    Text(Fmt.hours(today)).font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "play.fill").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Button {
                let h = Fmt.hours(today)
                if confirm("Reset today's time for \"\(task.name)\" (\(h)) to zero? Earlier days stay.") {
                    store.resetToday(task.name)
                }
            } label: {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("Reset today's time")
            Button {
                if confirm("Delete \"\(task.name)\" and its logged sessions?") {
                    store.removeTask(task.name)
                }
            } label: {
                Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("Delete task")
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(running ? Color(hex: "#16a34a").opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.primary.opacity(0.08)))
        .contentShape(Rectangle())
        .onTapGesture { if !running { store.start(task.name) } }
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            TextField("New task…", text: $newTask)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus").foregroundStyle(.white)
                    .frame(width: 32, height: 28)
            }
            .buttonStyle(.plain)
            .background(Color(hex: "#6366f1"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var todaySection: some View {
        let entries = store.todayByTask()
        let total = entries.reduce(0) { $0 + $1.seconds }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY").font(.system(size: 11, weight: .semibold)).tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(Fmt.hours(total)).font(.system(size: 15, weight: .semibold)).monospacedDigit()
            }
            if entries.isEmpty {
                Text("Nothing logged yet today.")
                    .font(.system(size: 13)).italic().foregroundStyle(.tertiary)
            } else {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(entries, id: \.task) { e in
                            Rectangle().fill(store.color(for: e.task))
                                .frame(width: max(2, geo.size.width * (e.seconds / total)))
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 5))

                ForEach(entries, id: \.task) { e in
                    HStack(spacing: 8) {
                        Circle().fill(store.color(for: e.task)).frame(width: 8, height: 8)
                        Text(e.task).font(.system(size: 13)).foregroundStyle(.secondary)
                        Spacer()
                        Text(Fmt.hours(e.seconds)).font(.system(size: 13, weight: .medium)).monospacedDigit()
                    }
                }
            }
        }
    }

    private func add() {
        store.addTask(newTask)
        newTask = ""
    }
}

@discardableResult
func confirm(_ message: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
}
