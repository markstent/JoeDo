import AppKit
import SwiftUI
import SwiftData

// Menu-bar icon for Joedo. Built on NSStatusItem directly rather than
// SwiftUI's MenuBarExtra so we can distinguish left-click from right-click:
// left-click toggles the popover with ContentView, right-click shows a menu
// (Settings… / Quit).
@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private override init() {
        super.init()
    }

    // Call on launch + whenever the AppMode changes.
    func setEnabled(_ enabled: Bool) {
        if enabled {
            if statusItem == nil {
                // Defer one runloop tick. Creating the status item too early
                // during app launch (especially in .accessory mode) reserves
                // the slot but silently skips rendering.
                DispatchQueue.main.async { [weak self] in
                    self?.performInstall()
                }
            }
        } else {
            uninstall()
        }
    }

    // Anchor a window (Settings, Help, etc.) under the menu-bar icon.
    // Public so other code paths can call it, but mostly used by the
    // global window-visibility observer below.
    func positionWindowUnderStatusItem(_ window: NSWindow) {
        guard let statusButton = statusItem?.button,
              let buttonWindow = statusButton.window else { return }
        let anchor = buttonWindow.convertToScreen(statusButton.frame)
        let wf = window.frame
        let screen = (NSScreen.main?.visibleFrame) ?? .zero
        var x = anchor.midX - wf.width / 2
        x = max(screen.minX + 6, min(x, screen.maxX - wf.width - 6))
        let y = anchor.minY - wf.height - 6
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func performInstall() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.isVisible = true
        item.behavior = []

        if let button = item.button {
            // Title acts as a belt-and-braces fallback — guarantees the slot
            // has SOMETHING visible even if every image fails to render.
            button.title = "Joedo"

            // Template first: macOS auto-tints it (white on dark menu bar,
            // black on light). White is a plain-white fallback for menu
            // bars that don't honour template tinting.
            let candidates: [(name: String, template: Bool)] = [
                ("JoeDoMenuBarTemplate", true),
                ("JoeDoMenuBarWhite",    false),
            ]
            var used = "sf-symbol-fallback"
            for c in candidates {
                if let image = NSImage(named: c.name) {
                    image.isTemplate = c.template
                    // Scale the image to 18pt tall, width proportional to
                    // the source aspect ratio. DON'T force square — our
                    // source icons are a ~2:1 wide banner.
                    let aspect = image.size.width / max(image.size.height, 1)
                    image.size = NSSize(width: 18 * aspect, height: 18)
                    button.image = image
                    button.imagePosition = .imageOnly
                    button.title = ""
                    used = c.name
                    break
                }
            }
            if button.image == nil,
               let sym = NSImage(systemSymbolName: "checklist",
                                 accessibilityDescription: "Joedo") {
                button.image = sym
                button.imagePosition = .imageOnly
                button.title = ""
                used = "sf-symbol-checklist"
            }

            NSLog("Joedo: menu-bar icon using \(used); image=\(button.image?.size ?? .zero) title='\(button.title)' window=\(button.window?.frame ?? .zero)")

            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 440, height: 560)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(
            rootView: CompactContentView()
                .modelContainer(JoedoModelStack.container)
                .frame(width: 440, height: 560)
        )
        popover = pop
    }

    private func uninstall() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        popover?.performClose(nil)
        popover = nil
    }

    @objc private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }
        switch event.type {
        case .rightMouseUp:
            presentContextMenu()
        default:
            togglePopover()
        }
    }

    // Public: show the popover if not already shown. Used by the tutorial
    // replay flow when the user is in Menu-Bar-Only mode (no main window).
    func showPopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    // Always toggle the popover on left-click. Same behaviour in both modes.
    private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // Temporarily assign a menu to the status item and trigger a click so
    // AppKit presents it; then clear it so the next left-click shows the
    // popover again rather than the menu.
    private func presentContextMenu() {
        guard let statusItem, let button = statusItem.button else { return }

        let menu = NSMenu()

        let helpItem = NSMenuItem(title: "Help…", action: #selector(openHelp), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(helpItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Joedo", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openHelp() {
        NSApp.activate(ignoringOtherApps: true)
        // Make sure ContentView (and its OpenHelpBridge) is alive to handle
        // the notification: open the popover briefly if nothing else shows.
        let popoverWasHidden = popover?.isShown == false
        if popoverWasHidden, let button = statusItem?.button, let pop = popover {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NotificationCenter.default.post(name: .joedoOpenHelp, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if popoverWasHidden { self?.popover?.performClose(nil) }
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        // Briefly show the popover so the OpenSettingsBridge view in
        // ContentView is alive to receive the notification, then hide it
        // once Settings has taken over.
        let popoverWasHidden = popover?.isShown == false
        if popoverWasHidden, let button = statusItem?.button, let pop = popover {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        // Fire the bridge route (preferred) plus the AppKit selector as fallback.
        NotificationCenter.default.post(name: .joedoOpenSettings, object: nil)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)

        // After the Settings window appears, anchor it under the menu-bar icon.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.positionSettingsUnderStatusItem()
            if popoverWasHidden { self?.popover?.performClose(nil) }
        }
    }

    private func positionSettingsUnderStatusItem() {
        guard let statusButton = statusItem?.button,
              let buttonWindow = statusButton.window else { return }

        let buttonScreenFrame = buttonWindow.convertToScreen(statusButton.frame)

        for window in NSApp.windows {
            let title = window.title.lowercased()
            guard title.contains("settings") || title.contains("preferences") else { continue }
            let wf = window.frame
            let screen = (NSScreen.main?.visibleFrame) ?? .zero
            var x = buttonScreenFrame.midX - wf.width / 2
            x = max(screen.minX + 6, min(x, screen.maxX - wf.width - 6))
            let y = buttonScreenFrame.minY - wf.height - 6
            window.setFrameOrigin(NSPoint(x: x, y: y))
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
