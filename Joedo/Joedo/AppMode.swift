import AppKit

// Where Joedo lives. Two modes:
//   • both:        Dock icon + menu-bar checklist, main window available.
//   • menuBarOnly: no Dock icon, menu-bar checklist only.
// Persisted as a raw string via @AppStorage("joedoAppMode").
enum AppMode: String, CaseIterable, Identifiable {
    case both = "both"
    case menuBarOnly = "menuBar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .both:        return "Window + Menu Bar"
        case .menuBarOnly: return "Menu Bar Only"
        }
    }

    // Whether a checklist icon appears in the system menu bar. Both modes
    // currently show it; kept as a property for consistency with earlier
    // wiring (and a future "Window only" mode if we reintroduce it).
    var showsMenuBar: Bool { true }

    // `.accessory` hides the Dock icon (menu-bar-only style);
    // `.regular` keeps it visible.
    var activationPolicy: NSApplication.ActivationPolicy {
        switch self {
        case .menuBarOnly: return .accessory
        case .both:        return .regular
        }
    }
}
