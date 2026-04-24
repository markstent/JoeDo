import SwiftUI
import AppKit

// A zero-size helper that reaches up to the hosting NSWindow and sets its
// frameAutosaveName. AppKit then persists window size + position to
// UserDefaults under that name and restores it on next launch — no manual
// observation or @AppStorage plumbing required.
struct WindowFrameAutosave: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            view.window?.setFrameAutosaveName(name)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
