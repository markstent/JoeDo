# Joedo — Clear-style Minimalist Todo App for macOS

## Context

Build **Joedo**, a personal-use macOS todo app that faithfully reproduces the look, feel, and core gestures of the **Clear** iOS app (useclear.com, Impending Inc.), distributed as a DMG installable on the user's own Mac.

- **Why:** The user wants Clear's fluid, chrome-free, gesture-driven interface on the desktop. Clear is iOS/iPadOS-only; there is no first-party Mac app.
- **Constraints chosen:**
  - Swift/SwiftUI (not Python; the `python/2026/` folder is organizational, not a requirement).
  - Local-only storage (no iCloud, no accounts, no $99/yr Apple Developer account needed).
  - Mac-only. Not a cross-platform app.
  - Ad-hoc signing; user will right-click → Open on first launch (standard for unsigned DMGs).
- **Scope:** Tier 1 (core Clear experience) + Tier 2 (keyboard hotkeys, reminders, themes, list sharing). Explicitly out of scope: Clear Cloud sync, Apple Watch, widgets, Spotlight, shop/collectibles/Pro, sound packs.

## Tech Stack & Architecture

- **UI:** SwiftUI (macOS 14 Sonoma minimum — unlocks SwiftData and modern gesture APIs).
- **Persistence:** SwiftData with `@Model` classes. Zero-config local SQLite, auto-save.
- **Undo:** `UndoManager` via `@Environment(\.undoManager)` (Cmd-Z free).
- **Audio:** `AVAudioPlayer` with bundled `.caf` files for swoosh / tick / ascending chimes.
- **Notifications (reminders):** `UserNotifications` framework (local notifications, no server).
- **Image export (share list):** `ImageRenderer` → PNG → `NSSavePanel`.
- **No third-party dependencies.**

### Data model (2 entities)

```swift
@Model final class TaskList {
    var id: UUID
    var title: String
    var order: Int
    var theme: String        // raw value of Theme enum
    var isArchived: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [TodoItem] = []
}

@Model final class TodoItem {
    var id: UUID
    var title: String
    var order: Int           // position in list = priority
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?       // optional reminder
    var repeatRule: String?  // "daily" | "weekly" | nil
    var list: TaskList?
}
```

Row heatmap color is **computed** from `order / list.items.count`, not stored. Priority == position.

### View hierarchy

- `JoedoApp` (App entry, `@main`) — `WindowGroup` with single `RootView`.
- `RootView` — `NavigationStack` hosting either `ListsHomeView` (Lists of Lists) or `TaskListView`.
- `ListsHomeView` — heatmap rows of `TaskList`s; tap to drill in, pinch-apart to insert.
- `TaskListView` — heatmap rows of `TodoItem`s; all gestures live here.
- `RowView<Content>` — generic row: full-bleed color slab, bold title, swipe/tap/drag modifiers.
- `SettingsView` — hidden (Cmd-,) pane: theme picker, volume, font size, show archived.

### Theming

`Theme` enum with `gradient(for index: Int, of count: Int) -> Color`. Ship 5 themes:
`heatmap` (red→yellow, default), `sunset` (magenta→orange), `nightOwl` (navy→teal), `grass` (dark green→lime), `ultraviolet` (deep purple→pink).

### Gestures & shortcuts (full matrix)

| Action | Trigger |
|---|---|
| Complete task | 2-finger swipe right OR click-drag right past threshold |
| Delete task | 2-finger swipe left OR click-drag left past threshold |
| Edit task | Single click on row |
| Add at top | Overscroll past top OR start typing with list focused |
| Add at bottom | Overscroll past bottom OR press Enter on last row |
| Insert between rows | Pinch-apart (`MagnificationGesture`) between two rows |
| Go up a level | Pinch-closed on list view |
| Reorder | Long-press then drag (`.draggable` + `.dropDestination`) |
| Undo | Cmd-Z |
| Redo | Cmd-Shift-Z |
| Switch to list 1–9 | Opt-1 … Opt-9 |
| Back / dismiss editor | Esc |
| Settings | Cmd-, |
| Share list as image | Cmd-Shift-S → save PNG |
| Toggle archive view | Cmd-Shift-A |

## Implementation phases

Phases 1–5 shipped; Phase 6 split into incremental sub-phases (6a–6f) for polish work. Each sub-phase independently verifiable.

### Phase 1 — Skeleton (proves persistence works)
- `xcodebuild` / Xcode: create macOS app project `Joedo` at `/Users/mark.stent/Projects/python/2026/todo_list/Joedo/`.
- Define `TaskList` and `TodoItem` `@Model`s.
- Default `List` view with add/delete. Ugly but persistent.
- **Verify:** add 3 tasks, quit (Cmd-Q), relaunch — tasks persist.

### Phase 2 — Visual identity (the "Clear look")
- Replace stock `List` with `LazyVStack` of custom `RowView`s.
- `RowView`: full-width, 64pt tall, flat color background, SF Pro Rounded Black 24pt white text, no dividers, no padding between rows.
- Compute row color from `Theme.heatmap.gradient(for: index, of: count)`.
- Window: `.windowStyle(.hiddenTitleBar)`, `.containerBackground(.regularMaterial, for: .window)`, hide toolbar. Traffic lights float over content.
- Dark background visible only at top/bottom overscroll.
- **Verify:** visually matches a Clear screenshot side-by-side.

### Phase 3 — Core gestures (the "Clear feel")
- `DragGesture` on `RowView`: translate row, show green checkmark icon when crossing +80pt, red X when crossing -80pt; on release past threshold, commit complete/delete with animation and sound.
- Tap → inline `TextField` (auto-focus, Esc dismisses, Enter commits + creates next row).
- Pull-down-to-add: detect overscroll via `ScrollView` + `GeometryReader`, spawn new empty row at top.
- **Verify:** can capture, complete, delete, edit tasks using only gestures — no buttons visible.

### Phase 4 — Pinch gestures
- `MagnificationGesture` on `RowView`: when two adjacent rows scale apart past threshold, insert a new blank row between them.
- `MagnificationGesture` on `TaskListView` (scale < 0.8): `dismiss()` back to `ListsHomeView`.
- Smooth spring animations on both.
- **Verify:** pinch between rows inserts; pinch closed navigates up.

### Phase 5 — Hierarchy (Lists of Lists)
- `ListsHomeView` with its own heatmap of `TaskList` rows (color derived from the list's theme).
- `NavigationStack` push into `TaskListView` on tap.
- Persist `TaskList.order` and `TaskList.theme`.
- Archive toggle (Cmd-Shift-A) filters `isArchived` lists.
- **Verify:** create 3 lists, drill into each, pinch back out to home.

### Phase 6 — Polish (shipped across 6a-6c)

- **6a Sounds** ✅ — `NSSound` with Glass/Basso/Pop (AVAudioEngine tone generation attempted first but silently failed; NSSound with `.copy()` on named cached instance is what works).
- **6b Themes + Settings** ✅ — 5 themes (heatmap, sunset, nightOwl, grass, ultraviolet). macOS Settings scene (⌘,) with theme picker + live preview, volume slider (bound to `AudioController`), show-archived toggle. Global theme via `@AppStorage("joedoTheme")`.
- **6c Reorder** ✅ — Drag handle on the left of each row (hover-reveal `line.3.horizontal` grip) with `.draggable(uuidString)` + `.dropDestination(for: String.self)`. Context-menu Move Up/Down/To-Top/To-Bottom alongside. Drag handle is a **sibling** view to the row body so it can't collide with the row's `DragGesture` (swipe).
- **Pinch-to-add via `NSEvent.addLocalMonitorForEvents(matching: [.magnify])`** — bypasses SwiftUI gesture arena entirely (per-row `MagnifyGesture` + per-row `DragGesture` broke swipe twice; NSEvent monitor doesn't). Installed in each view's `.onAppear`, removed in `.onDisappear`.
- **Keyboard shortcuts** on every context-menu item:
  - Tasks: ⌘Return (complete), ⇧⌘↑/↓ (top/bottom), ⌥⌘↑/↓ (up/down), ⌘⌫ (delete).
  - Lists: ⌘R (rename), same move shortcuts, ⌘E (archive), ⌘⌫ (delete).
- **Click-anywhere-below-rows = add** — invisible tap target fills the remaining scroll space.
- **Minimalist add affordance** — just a subtle `+` at 30% white opacity (replaced "Click or ⌘N to add…" text).
- **"Lists" header on home + list-name header on task view** — 28pt black rounded, centered; task view also has `← Lists` back affordance on the left.

### Phase 6d — Ship-completion polish (Tier A, queued)

High-value small wins that together make the app feel finished. Each independently verifiable.

- **Undo / Redo (⌘Z / ⇧⌘Z).** Wire SwiftUI's `UndoManager` via `@Environment(\.undoManager)`. Register undo for every mutating action:
  - add task/list
  - delete task/list
  - toggle complete
  - rename (title edits are continuous — register as a single undo group per edit session)
  - reorder (move up/down/top/bottom, drag-drop)
  - archive/unarchive list
- **Completed count on home rows.** Small `3/7`-style indicator on the right of each list row (e.g. 12pt rounded, white at 50%). Computed live from the list's `items` collection. Tiny code change, big at-a-glance value.
- **Clear Completed per list.** Right-click on a task list on home → "Clear Completed" (⌘⇧K). Also available in the task view's context menu background or as an app command. Animates completed rows out one by one.
- **Window state memory.** Persist `NSWindow.frame` to `UserDefaults` via `AppStorage` or a `.onChange(of: frame)`. Restore on next launch. Covers size AND position.

**Verify:** delete a list, ⌘Z → list returns with all tasks. Home row for a 5-item list shows `2/5` after completing two. ⌘⇧K on a list with 3 completed + 4 active → animates 3 out, leaves 4. Resize window, quit, relaunch — same size/position.

### Phase 6e — Power-user features (Tier B, queued)

- **Menu-bar mode.** Joedo runs as an `NSStatusItem` menu-bar app. Click the icon → popover shows today's list (or last-opened). `LSUIElement = YES` option so it doesn't show in the dock. Keep the main window accessible (e.g. right-click → "Open Window"). Bigger architectural change: introduce a `MenuBarController` that manages both the popover and the main window.
- **Global hotkey for quick-add.** Default ⌥⌘J. Registers via `NSEvent.addGlobalMonitorForEvents` or the newer `HotKey` API. On trigger, a small borderless floating window slides in from screen-top-center → single `TextField` → Enter commits to the default list (configurable in Settings) → window closes. Cancellable with Esc.
- **Search (⌘F).** Thin search bar overlay at top of any list; filters rows in place. Clears on Esc. Single-list only for v1; cross-list search is Phase 6f.

**Verify:** menu-bar icon shows count badge; popover opens lists and is usable end-to-end. Global hotkey from any app brings up the quick-add; capture goes into the correct list. ⌘F filters visible rows.

### Phase 6f — Polish flourishes (Tier C, queued)

- **Dock badge with un-completed count.** Sum across non-archived lists. `NSApp.dockTile.badgeLabel = "12"`. Keep in sync via a lightweight observer on the model context.
- **Auto-fade completed.** When a task's `isCompleted` turns true, hold visible for ~3s, then animate `.opacity(0)` + collapse row height. Still persisted in the data so "Clear Completed" / "Show Completed" toggle work later. Respect a "Keep completed visible" setting for users who want them to stick around.
- **Font-size stepper in Settings.** Plumbs into `Typography.row(size:)` via `@AppStorage("joedoFontSize")`. Range 16–28pt.
- **Drag a task onto a list on home** → move task between lists. Home list rows become drop targets for task UUID strings; on drop, update `item.list = targetList` and renumber both.

**Verify:** dock badge tracks live as tasks are added/completed. Toggling "Keep completed visible" off → completed tasks fade. Font-size stepper resizes every row instantly. Drag a task from inside a list, pinch-close to navigate home, drop on another list row — task migrates.

### Phase 6h — First-run tutorial + Help window (in progress)

**Why:** first-time users see a blank home screen with no idea how any of Joedo's gestures work. Discoverability of swipe / pinch / drag handle / Cmd-N routing is currently zero without reading documentation that doesn't exist.

**What ships:**

- **Guided hands-on tutorial** — auto-opens on first launch, translucent dim overlay with a spotlight cutout over a specific UI element, instruction card floats near (not over) the spotlight. The user must actually perform the expected action (click +, type name, swipe row) to advance. Skippable, resumable across app quits, replayable from Help / Settings.
- **Help window** — separate non-blocking `Window(id: "help")` scene with comprehensive reference: Lists, Tasks, Gestures, Keyboard Shortcuts table, App Location modes, Themes, Replay Tutorial button.
- **Menu-bar right-click** gets a new **Help…** item above Settings…, plus separator, then Quit.

**Architecture:**

- `Tutorial/TutorialController.swift` — `@Observable @MainActor` singleton. Tracks `step: TutorialStep`, `isActive: Bool`, persists progress via `@AppStorage("joedoTutorialStep")` and `@AppStorage("joedoHasSeenTutorial")`.
- `Tutorial/TutorialStep.swift` — enum of 11 steps with titles, instructions, optional anchor IDs, manual-advance flag. Also defines `TutorialAction` enum.
- `Tutorial/TutorialAnchor.swift` — `TutorialAnchorID` enum + `tutorialAnchor(_:)` view modifier that reports frames via `TutorialAnchorsKey: PreferenceKey` in a `.tutorial` coordinate space.
- `Tutorial/TutorialOverlay.swift` — `ZStack` overlay: dim layer with even-odd-fill cutout over anchor rect, floating card anchored above or below the spotlight. Empty-anchor steps use a full-window dim + centered card.
- `Views/HelpWindow.swift` — scrollable SwiftUI reference content with a Replay Tutorial button.
- Wiring: `ListsHomeView`'s `addNewList`, `handleTap`, and `commitEdit` (via `setEditing(to: nil)` path) call `TutorialController.shared.didPerform(.addedList / .openedList / .namedList)`. Same pattern in `TaskListView` for `addNewTopTask`, `toggleComplete`, `delete`, `setEditing`. Anchors attached to `+` buttons and first-row rendering in both views.
- `ContentView.swift` overlays `TutorialOverlay(anchors:)` above the `NavigationStack`, reading `TutorialAnchorsKey` via `.onPreferenceChange` and passing the dictionary down.
- `JoedoApp.swift` adds `Window(id: "help") { HelpView() }` and a `CommandGroup` replacing nothing, just ensuring the Help window can be opened with Cmd-?.
- `MenuBarController.swift` adds `Help…` menu item that fires `.joedoOpenHelp`; new `OpenHelpBridge` in `ContentView.swift` calls `openWindow(id: "help")` in response.

**Verify:**

1. Fresh launch (delete `joedoHasSeenTutorial` from defaults) → overlay appears with Welcome card → Start → each step progresses as user performs the action → Finish closes it and persists `hasSeenTutorial = true`.
2. Relaunch → overlay does NOT reopen.
3. Settings → Replay Tutorial → overlay opens again.
4. Right-click menu-bar icon → Help… → help window opens, contains full shortcut list, Replay Tutorial button works.
5. Swipe/pinch/drag still work with tutorial active and dismissed.

### Phase 6g — Deferred / explicitly out-of-scope for now

- **Reminders / due dates (`UserNotifications` framework).** In the original plan; still desirable. Not scheduled because it adds a meaningful permission flow (notifications) and complicates the data model with repeat rules. Easy to add later without re-architecting.
- **Share list as image (`ImageRenderer` → `NSSavePanel`).** Nice-to-have, low priority.
- **Pinch-between-rows to insert (Clear's exact gesture).** Dropped — SwiftUI's `MagnifyGesture` doesn't expose touch location and per-row gestures collide with swipe. Current workarounds (pinch-apart-anywhere = add at top) are acceptable.

**Verify each Phase 6 sub-phase independently.** Swipe-complete / swipe-delete is the canary — if it breaks after any change, regression is in gesture territory (see `docs/` and memory notes for the rules).

### Phase 7 — DMG packaging
- Create `scripts/build_dmg.sh`:
  ```bash
  xcodebuild -project Joedo.xcodeproj -scheme Joedo -configuration Release \
    -archivePath build/Joedo.xcarchive archive
  xcodebuild -exportArchive -archivePath build/Joedo.xcarchive \
    -exportPath build/export -exportOptionsPlist scripts/ExportOptions.plist
  codesign --force --deep --sign - build/export/Joedo.app
  create-dmg --volname "Joedo" --window-size 500 300 \
    --icon "Joedo.app" 125 150 --app-drop-link 375 150 \
    build/Joedo.dmg build/export/
  ```
- `ExportOptions.plist` with `method = mac-application`, `signingStyle = manual`.
- Prerequisite: `brew install create-dmg`.
- Add `Makefile` with `make dmg` target.
- **Verify:** on a fresh macOS user account (or after moving `~/Applications/Joedo.app` aside), double-click `Joedo.dmg`, drag to Applications, right-click → Open, confirm Gatekeeper prompt once, app launches.

## Critical files (to create — fresh project, nothing to modify)

```
/Users/mark.stent/Projects/python/2026/todo_list/
├── Joedo.xcodeproj/                    # Xcode-generated
├── Joedo/
│   ├── JoedoApp.swift                  # @main entry, WindowGroup, modelContainer
│   ├── Models/
│   │   ├── TaskList.swift              # @Model
│   │   └── TodoItem.swift              # @Model
│   ├── Views/
│   │   ├── RootView.swift
│   │   ├── ListsHomeView.swift
│   │   ├── TaskListView.swift
│   │   ├── RowView.swift               # core row component (gestures live here)
│   │   └── SettingsView.swift
│   ├── Theme/
│   │   ├── Theme.swift                 # enum + gradient(for:of:)
│   │   └── Typography.swift            # SF Pro Rounded Black extensions
│   ├── Audio/
│   │   ├── AudioController.swift       # AVAudioPlayer wrapper
│   │   └── Sounds/                     # .caf files
│   ├── Notifications/
│   │   └── ReminderScheduler.swift     # UNUserNotificationCenter
│   └── Assets.xcassets/                # app icon, accent color
├── scripts/
│   ├── build_dmg.sh
│   └── ExportOptions.plist
└── Makefile
```

No existing code to reuse — this is a greenfield project.

## Verification (end-to-end test plan)

Manual smoke test after each phase. Final acceptance run after Phase 7:

1. **Fresh install:** double-click `build/Joedo.dmg` → drag to `/Applications` → right-click → Open → allow via Gatekeeper → app launches to empty Lists home.
2. **Create list:** pull-down-to-add on home → type "Groceries" → Enter. List appears as red row.
3. **Drill in:** click "Groceries" → land on task list view.
4. **Add tasks:** pull down, add 5 tasks. Verify top row is deepest red, bottom row is yellow (heatmap).
5. **Complete task:** swipe top row right → green check flashes, ascending chime plays, row animates out, remaining rows re-color.
6. **Delete task:** swipe a row left → red X flashes, swoosh plays, row removed.
7. **Insert between:** pinch apart between rows 2 and 3 → new editable row appears between them.
8. **Reorder:** long-press row, drag to new position → re-colors reflect new priority.
9. **Pinch up:** pinch closed → navigates back to Lists home.
10. **Undo:** Cmd-Z repeatedly → every action reverses in order.
11. **Hotkeys:** Opt-2 jumps to 2nd list; Esc dismisses editor; Cmd-, opens settings.
12. **Theme switch:** Settings → pick Sunset → all rows recolor with magenta→orange gradient.
13. **Reminder:** add a task with due-date 1 min in future → macOS Notification Center banner fires on time.
14. **Share image:** Cmd-Shift-S on a list → PNG saved to Desktop matches on-screen look.
15. **Persistence:** Cmd-Q → relaunch → all lists, tasks, completion state, themes preserved.
16. **Archive:** Cmd-Shift-A toggles showing archived lists.

## Open questions / flags for implementation time

- **Sound assets:** Clear's chimes are bespoke. I'll generate simple ascending sine-wave `.caf` files in Audacity/Logic during Phase 6; user can swap in preferred sounds later.
- **Font:** Clear uses a custom font; SF Pro Rounded Black (system) is the closest free match and ships with macOS. No licensing issues.
- **Trackpad-only gestures:** pinch and multi-finger swipe require a trackpad or Magic Mouse. Single-button mouse users get click-drag fallbacks for swipe; pinch has no mouse fallback (acceptable — user is on a Mac with trackpad).
- **macOS 14 floor:** locks out Macs older than ~2018. Acceptable since user is on macOS 15.
