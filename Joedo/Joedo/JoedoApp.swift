import SwiftUI
import SwiftData
import AppKit
import Carbon

@main
struct JoedoApp: App {
    @NSApplicationDelegateAdaptor(JoedoAppDelegate.self) private var appDelegate

    init() {
        let stored = UserDefaults.standard.object(forKey: "joedoVolume") as? Double
        AudioController.shared.volume = Float(stored ?? 0.6)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .background(WindowFrameAutosave(name: "JoedoMainWindow"))
        }
        .modelContainer(JoedoModelStack.container)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .joedoAddNew, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("Settings…")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .sidebar) {
                Button("Back to Lists") {
                    NotificationCenter.default.post(name: .joedoGoBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)
            }
            CommandMenu("List") {
                Button("Clear Completed") {
                    NotificationCenter.default.post(name: .joedoClearCompletedCurrent, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                Button("Find") {
                    NotificationCenter.default.post(name: .joedoFocusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
        .modelContainer(JoedoModelStack.container)

        Window("Joedo Help", id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
    }
}

final class JoedoAppDelegate: NSObject, NSApplicationDelegate {
    private var hotkey: GlobalHotkey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Joedo: applicationDidFinishLaunching")
        DefaultData.seedIfEmpty()
        installGlobalHotkeyIfEnabled()
        installSettingsWindowObserver()
        installMenuBarOnlyWindowReaper()

        // Apply user's configured mode immediately. Default on fresh
        // install is Menu-Bar-Only.
        applyCurrentMode()

        // Welcome is a separate floating panel — works in any mode,
        // including accessory. Briefly delayed so the status item is in
        // place and seeded lists exist.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WelcomeWindowController.shared.showIfFirstLaunch()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            InstallerHelper.offerMoveToApplicationsIfNeeded()
        }
    }

    // Global observer: whenever a SwiftUI main window becomes visible AND
    // we're in Menu-Bar-Only mode, close it. SwiftUI sometimes recreates
    // the WindowGroup window after policy changes; this keeps it dismissed.
    private func installMenuBarOnlyWindowReaper() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard self.currentMode() == .menuBarOnly else { return }
            // Don't touch windows while the welcome is pending — the
            // overlay's main window is legitimate then.
            guard UserDefaults.standard.bool(forKey: "joedoWelcomeShown") else { return }
            guard let window = note.object as? NSWindow else { return }
            let cls = window.className
            guard cls.contains("SwiftUI") else { return }
            let title = window.title.lowercased()
            if title.contains("settings") || title.contains("preferences") { return }
            if title.contains("help") { return }
            NSLog("Joedo: reaping unwanted window '\(window.title)'")
            window.close()
        }
    }

    // Called by the welcome overlay when the user dismisses it — flips the
    // app into whatever mode they actually configured (usually menu-bar-only).
    // Slight delay so the @AppStorage write + overlay dismiss animation
    // complete before we yank the window out from under the user.
    func applyCurrentModeAfterWelcome() {
        let stored = UserDefaults.standard.string(forKey: "joedoAppMode")
        let computed = currentMode()
        NSLog("Joedo: applyCurrentModeAfterWelcome stored=\(stored ?? "nil") computed=\(computed.rawValue)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.applyCurrentMode()
            // Belt + braces — if any main window survived the policy change,
            // force-close it when we're in menu-bar-only.
            if self.currentMode() == .menuBarOnly {
                for w in NSApp.windows where w.frameAutosaveName == "JoedoMainWindow" {
                    NSLog("Joedo: force-closing main window after welcome")
                    w.close()
                }
            }
        }
    }

    // Re-anchor Settings / Help windows under the menu-bar icon whenever
    // they become visible, no matter how they were opened (⌘, / menu /
    // right-click / programmatic). Defers a tick so the window's own
    // frame is correct before we move it.
    // Track which Settings windows we've already positioned so we don't
    // re-anchor them every time they're focused (which would undo the
    // user's manual drag).
    private var anchoredSettingsWindows = Set<ObjectIdentifier>()

    private func installSettingsWindowObserver() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, let window = note.object as? NSWindow else { return }
            let title = window.title.lowercased()
            guard title.contains("settings") || title.contains("preferences") else { return }
            let id = ObjectIdentifier(window)
            guard !self.anchoredSettingsWindows.contains(id) else { return }
            self.anchoredSettingsWindows.insert(id)
            DispatchQueue.main.async {
                MenuBarController.shared.positionWindowUnderStatusItem(window)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        currentMode() != .menuBarOnly
    }

    private func currentMode() -> AppMode {
        AppMode(rawValue: UserDefaults.standard.string(forKey: "joedoAppMode") ?? "") ?? .menuBarOnly
    }

    func applyCurrentMode() {
        let mode = currentMode()
        NSLog("Joedo: applyCurrentMode mode=\(mode.rawValue) showsMenuBar=\(mode.showsMenuBar)")
        NSApp.setActivationPolicy(mode.activationPolicy)
        MenuBarController.shared.setEnabled(mode.showsMenuBar)
        if mode == .menuBarOnly {
            // Delay so WindowGroup has time to create its window before we
            // try to close it. Run again at a longer delay as a safety net.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.closeMainWindow()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.closeMainWindow()
            }
        }
    }

    // Close only the SwiftUI WindowGroup's main window. We deliberately
    // match on the SwiftUI AppKit-window class name so NSStatusBarWindow
    // (the menu-bar icon) is never touched. Settings / Help are excluded
    // by title.
    private func closeMainWindow() {
        NSLog("Joedo: closeMainWindow scanning \(NSApp.windows.count) windows")
        for window in NSApp.windows {
            guard window.isVisible else { continue }
            let cls = window.className
            // Only SwiftUI-managed windows are candidates. Everything else
            // (NSStatusBarWindow, NSPanel, system windows) stays.
            guard cls.contains("SwiftUI") else { continue }
            let title = window.title.lowercased()
            if title.contains("settings") || title.contains("preferences") { continue }
            if title.contains("help") { continue }
            NSLog("Joedo:   closing window title='\(window.title)' class=\(cls)")
            window.close()
        }
    }

    // Register ⌃⌘J system-wide. Two modifiers — simpler than three.
    func installGlobalHotkeyIfEnabled() {
        hotkey = nil
        let enabled = (UserDefaults.standard.object(forKey: "joedoQuickAddHotkey") as? Bool) ?? true
        guard enabled else { return }

        hotkey = GlobalHotkey(
            keyCode: UInt32(kVK_ANSI_J),
            modifiers: UInt32(controlKey | cmdKey),
            callback: {
                QuickAddWindowController.shared.show()
            }
        )
    }
}
