# Tempo — Activity Timer (macOS menu-bar app)

Native macOS menu-bar app to track time on daily tasks. Lives in the top bar like Docker/Teams: shows the running timer live, click for the task dropdown, open a stats window for daily/weekly analysis.

Native rewrite of the [activity-timer](https://github.com/ghosharkaprava8/activity-timer) Chrome extension.

## Features

- Menu-bar dropdown: custom task list with per-task colors, one-tap start/stop, live elapsed timer, today summary.
- Live elapsed time shown in the menu bar while running.
- Stats window: KPI cards (today / week / daily avg / streak), hours-per-day chart, per-task breakdown, session log, week navigation.
- Per-task reset of today's time (earlier days untouched).
- Runaway-timer guards: stops on system sleep, on 5 min idle (trims away-time), and a 4 h hard cap.
- Local storage only — JSON at `~/Library/Application Support/Tempo/data.json`. No account, no network.

## Build & run

Requires the Swift toolchain (Command Line Tools is enough; Xcode not required).

```bash
./build.sh          # compiles + assembles Tempo.app
open Tempo.app      # launches into the menu bar
```

Install: copy `Tempo.app` to `/Applications`. To auto-start, add it under System Settings → General → Login Items.

> Note: Command Line Tools' SwiftPM manifest linking is broken, so the build invokes `swiftc` directly (see `build.sh`). `Package.swift` is kept for full-Xcode users.

## Project layout

```
Sources/Tempo/
  main.swift          entry point
  AppDelegate.swift   status item, popover, live title, sleep/idle guards
  Models.swift        TaskItem / Session / AppData (Codable)
  Store.swift         JSON persistence, start/stop/reset, aggregation
  MenuView.swift      dropdown UI
  StatsView.swift     stats window UI
  Idle.swift          IOKit system idle time
  Format.swift        time formatting
  Color+Hex.swift     hex → SwiftUI Color
```

## Storage model

```
tasks:    [{ name, color }]
active:   { task, start } | null
sessions: [{ id, task, start, end }]   // start/end = seconds since epoch
```
