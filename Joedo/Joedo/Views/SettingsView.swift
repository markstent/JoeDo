import SwiftUI
import SwiftData

// The Settings window (⌘,). Groups preferences by concern — Appearance,
// Sound, App Location, Behaviour, Quick Add, Tutorial, Data.
struct SettingsView: View {
    @Environment(\.openWindow) private var openWindow

    @AppStorage("joedoTheme") private var themeRaw: String = Theme.heatmap.rawValue
    @AppStorage("joedoVolume") private var volume: Double = 0.6
    @AppStorage("joedoShowArchived") private var showArchived: Bool = false
    @AppStorage("joedoAppMode") private var appModeRaw: String = AppMode.menuBarOnly.rawValue
    @AppStorage("joedoQuickAddHotkey") private var quickAddHotkey: Bool = true

    @State private var confirmReset: Bool = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeRaw) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                themeSlabPreview
            }

            Section("App Location") {
                Picker("Show", selection: $appModeRaw) {
                    ForEach(AppMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .onChange(of: appModeRaw) { _, new in
                    let mode = AppMode(rawValue: new) ?? .menuBarOnly
                    applyAppModeChange(mode)
                }
                Text(locationHint)
                    .font(DS.Typo.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Sound") {
                HStack {
                    Image(systemName: "speaker.wave.1")
                        .foregroundStyle(.secondary)
                    Slider(value: $volume, in: 0...1)
                        .onChange(of: volume) { _, new in
                            AudioController.shared.volume = Float(new)
                        }
                    Image(systemName: "speaker.wave.3")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Home") {
                Toggle("Show archived lists", isOn: $showArchived)
            }

            Section("Quick Add") {
                Toggle("Global hotkey ⌃⌘J", isOn: $quickAddHotkey)
                    .onChange(of: quickAddHotkey) { _, _ in
                        (NSApp.delegate as? JoedoAppDelegate)?.installGlobalHotkeyIfEnabled()
                    }
                Text("Press ⌃⌘J from any app. Type, hit Enter — it lands in your top list.")
                    .font(DS.Typo.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Data") {
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Text("Reset All Data…")
                }
                Text("Deletes every list and task. Cannot be undone.")
                    .font(DS.Typo.caption)
                    .foregroundStyle(.secondary)

                Button("Show Welcome Again") {
                    UserDefaults.standard.set(false, forKey: "joedoWelcomeShown")
                    UserDefaults.standard.synchronize()
                }
                Text("Re-display the welcome screen next time the main window opens.")
                    .font(DS.Typo.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 620)
        .onAppear { AudioController.shared.volume = Float(volume) }
        .confirmationDialog("Delete all lists and tasks?",
                            isPresented: $confirmReset,
                            titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove every list and task. There is no undo.")
        }
    }

    // MARK: - Theme preview

    // One big 56pt slab showing the theme's gradient with the theme name
    // baked in — matches the visual language of the app's rows.
    private var themeSlabPreview: some View {
        let theme = Theme(rawValue: themeRaw) ?? .heatmap
        return ZStack {
            LinearGradient(
                colors: (0..<6).map { theme.color(for: $0, of: 6) },
                startPoint: .top,
                endPoint: .bottom
            )
            Text(theme.displayName)
                .font(DS.Typo.row)
                .foregroundStyle(.white)
        }
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }

    private var locationHint: String {
        switch AppMode(rawValue: appModeRaw) ?? .menuBarOnly {
        case .both:        return "Dock icon + menu-bar checklist."
        case .menuBarOnly: return "Menu-bar checklist only. No Dock icon."
        }
    }

    // MARK: - Actions

    private func applyAppModeChange(_ mode: AppMode) {
        NSApp.setActivationPolicy(mode.activationPolicy)
        MenuBarController.shared.setEnabled(mode.showsMenuBar)

        switch mode {
        case .menuBarOnly:
            for window in NSApp.windows where window.frameAutosaveName == "JoedoMainWindow" {
                window.close()
            }
        case .both:
            let hasMainWindow = NSApp.windows.contains { $0.frameAutosaveName == "JoedoMainWindow" }
            if !hasMainWindow {
                openWindow(id: "main")
            }
        }
    }

    // Delete every TaskList (cascades tasks via the model relationship).
    @MainActor
    private func resetAllData() {
        let context = ModelContext(JoedoModelStack.container)
        let descriptor = FetchDescriptor<TaskList>()
        if let all = try? context.fetch(descriptor) {
            for list in all { context.delete(list) }
            try? context.save()
        }
    }
}

#Preview {
    SettingsView()
}
