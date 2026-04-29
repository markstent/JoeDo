import SwiftUI

// Help content shown in its own non-blocking Window(id: "help").
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                header
                section("Lists", lines: [
                    "Home shows all your lists. The number on the right is done / total.",
                    "Click a list to open it.",
                    "Click the + at the top, or ⌘N, to create a new list.",
                    "Right-click a list for Rename, Move, Archive, Clear Completed, Delete.",
                    "Swipe right on a list to archive it. Swipe left to delete.",
                ])
                divider
                section("Tasks", lines: [
                    "Inside a list, click the + or ⌘N to add a task.",
                    "Click a task to edit its title. Enter commits. Esc cancels.",
                    "Swipe right to complete. Swipe left to delete.",
                    "Right-click for the full menu with shortcuts.",
                ])
                divider
                section("Gestures", lines: [
                    "Swipe right past the threshold: complete the task (or archive a list).",
                    "Swipe left past the threshold: delete.",
                    "Hover a row: a small grip (≡) appears on the left. Drag the grip to reorder.",
                    "Pinch apart on the trackpad: add a new task/list.",
                ])
                divider
                shortcuts
                divider
                section("App location", lines: [
                    "Settings → App Location: Window Only, Menu Bar Only, or Both.",
                    "Menu Bar Only hides the Dock icon — click the menu-bar checklist to open.",
                    "Right-click the menu-bar icon: Help, Settings, Quit.",
                ])
                divider
                section("Quick Add hotkey", lines: [
                    "Press ⌃⌥⌘J from any app to pop up a capture field.",
                    "Type and Enter to add to your top list.",
                    "Toggle in Settings → Quick Add.",
                ])
                divider
                section("Themes", lines: [
                    "Heatmap, Sunset, Night Owl, Grass, Ultraviolet.",
                    "Change in Settings → Appearance. Applies instantly.",
                ])
            }
            .padding(DS.Space.xl)
            .frame(maxWidth: 680, alignment: .leading)
        }
        .frame(minWidth: 560, minHeight: 520)
        .navigationTitle("Joedo Help")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "checklist")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Joedo Help")
                    .font(DS.Typo.display)
            }
            Text("A minimalist, gesture-driven to-do app. Everything happens by click, swipe, drag, or shortcut.")
                .font(DS.Typo.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(height: 1)
    }

    // MARK: - Section + shortcuts

    private func section(_ title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(title)
                .font(DS.Typo.section)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: DS.Space.xs) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(line)
                        .font(DS.Typo.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text("Keyboard shortcuts")
                .font(DS.Typo.section)
            shortcutRow("⌘N",          "New list / new task")
            shortcutRow("⌘F",          "Search the current screen")
            shortcutRow("⌘[",          "Back to Lists")
            shortcutRow("⌘Z / ⇧⌘Z",     "Undo / Redo")
            shortcutRow("⇧⌘K",         "Clear completed tasks")
            shortcutRow("⌘,",          "Open Settings")
            shortcutRow("⌃⌘J",         "Quick-add from any app")
            Text("Inside a right-click menu:")
                .font(DS.Typo.caption)
                .foregroundStyle(.secondary)
                .padding(.top, DS.Space.xs)
            shortcutRow("⌘↩",           "Mark complete / incomplete")
            shortcutRow("⌥⌘↑ / ⌥⌘↓",    "Move up / down")
            shortcutRow("⇧⌘↑ / ⇧⌘↓",    "Move to top / bottom")
            shortcutRow("⌘⌫",           "Delete")
            shortcutRow("⌘R",           "Rename (on a list)")
            shortcutRow("⌘E",           "Archive / unarchive")
        }
    }

    private func shortcutRow(_ key: String, _ desc: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Space.md) {
            Text(key)
                .font(DS.Typo.mono)
                .frame(width: 120, alignment: .trailing)
            Text(desc)
                .font(DS.Typo.body)
        }
    }

}
