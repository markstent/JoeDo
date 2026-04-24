import SwiftUI
import AppKit

// First-launch welcome as a borderless floating NSPanel.
// Lives independently of WindowGroup / popover so it works in any
// activation policy (Menu-Bar-Only, Window+Menu, etc.). Click the
// image or outside the panel to dismiss; persists a flag so it never
// re-shows unless explicitly reset from Settings.
@MainActor
final class WelcomeWindowController {
    static let shared = WelcomeWindowController()

    private var window: FloatingWelcomePanel?
    private var resignObserver: Any?

    private init() {}

    func showIfFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: "joedoWelcomeShown") else {
            NSLog("Joedo: welcome already shown")
            return
        }
        NSLog("Joedo: showing welcome panel")
        show()
    }

    func show() {
        let size = NSSize(width: 420, height: 424)

        if window == nil {
            let hosting = NSHostingController(
                rootView: WelcomeImageView(onTap: { [weak self] in self?.dismiss() })
                    .frame(width: size.width, height: size.height)
            )

            let p = FloatingWelcomePanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.contentViewController = hosting
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.level = .floating
            p.collectionBehavior = [.canJoinAllSpaces]
            p.isReleasedWhenClosed = false
            window = p
        }

        // Explicitly center on the screen's visible frame. NSWindow.center()
        // misbehaves for borderless panels at high levels.
        if let window, let screen = NSScreen.main ?? NSScreen.screens.first {
            let vf = screen.visibleFrame
            let origin = NSPoint(
                x: vf.midX - size.width / 2,
                y: vf.midY - size.height / 2
            )
            window.setFrame(NSRect(origin: origin, size: size), display: false)
        }

        window?.orderFrontRegardless()
        window?.makeKey()
        installResignObserver()
        NSLog("Joedo: welcome panel frame=\(window?.frame ?? .zero)")
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: "joedoWelcomeShown")
        UserDefaults.standard.synchronize()
        removeResignObserver()
        window?.close()
        window = nil
    }

    private func installResignObserver() {
        removeResignObserver()
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { _ in
            Task { @MainActor in WelcomeWindowController.shared.dismiss() }
        }
    }

    private func removeResignObserver() {
        if let token = resignObserver {
            NotificationCenter.default.removeObserver(token)
            resignObserver = nil
        }
    }
}

// Borderless panels can't become key by default — required override so
// focus loss (and therefore didResignKey) fires when the user clicks
// outside the panel.
private final class FloatingWelcomePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private struct WelcomeImageView: View {
    let onTap: () -> Void

    var body: some View {
        Image("WelcomeHero")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
    }
}
