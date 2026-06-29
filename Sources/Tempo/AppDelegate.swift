import AppKit
import SwiftUI

let IDLE_LIMIT: Double = 300          // 5 min idle → stop, trim away-time
let MAX_SESSION: Double = 4 * 3600    // hard cap 4 h (sleep safety net)

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var tickTimer: Timer?
    private var statsWindow: NSWindow?

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory) // menu-bar only, no Dock icon

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "stopwatch", accessibilityDescription: "Tempo")
            button.image?.isTemplate = true
            button.imagePosition = .imageLeading
            // Fixed-width digits so the bar item doesn't shift as the time ticks.
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuView(store: store, openStats: { [weak self] in self?.openStats() },
                               quit: { NSApp.terminate(nil) })
        )

        // Guards
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification, object: nil)

        tickTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                         selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(tickTimer!, forMode: .common)
        tick()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func tick() {
        guard let active = store.data.active else {
            statusItem.button?.title = ""
            return
        }
        let now = Date().timeIntervalSince1970

        // Idle guard: stop, ending when input actually stopped.
        let idle = systemIdleSeconds()
        if idle >= IDLE_LIMIT {
            store.stop(at: now - idle)
            statusItem.button?.title = ""
            return
        }
        // Hard cap (catches sleep that skipped the notification).
        if now - active.start > MAX_SESSION {
            store.stop(at: active.start + MAX_SESSION)
            statusItem.button?.title = ""
            return
        }
        statusItem.button?.title = " " + Fmt.barClock(now - active.start)
    }

    @objc private func systemWillSleep() {
        store.stop(at: Date().timeIntervalSince1970)
    }

    private func openStats() {
        popover.performClose(nil)
        if statsWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered, defer: false)
            win.title = "Tempo — Stats"
            win.center()
            win.isReleasedWhenClosed = false
            win.contentViewController = NSHostingController(rootView: StatsView(store: store))
            statsWindow = win
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        statsWindow?.makeKeyAndOrderFront(nil)
    }
}
