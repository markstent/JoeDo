# JoeDo Tutorial

<p align="center">
  <img src="source-assets/JoeDo_Readme_Image.png" alt="JoeDo" width="720" />
</p>

Everything you need to know about using JoeDo, from the first launch to the last dusty corner of the Settings pane.

## Contents
- [Your first launch](#your-first-launch)
- [Opening JoeDo](#opening-joedo)
- [Lists](#lists)
- [Tasks](#tasks)
- [Gestures](#gestures)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Quick Add from anywhere](#quick-add-from-anywhere)
- [Menu bar right-click menu](#menu-bar-right-click-menu)
- [Settings, field by field](#settings-field-by-field)
- [Undo and redo](#undo-and-redo)
- [Troubleshooting](#troubleshooting)

## Your first launch

When you first open JoeDo, a welcome image floats over your screen. Click it (or anywhere outside it) to dismiss. It only appears once.

JoeDo ships with two starter lists so you can see what it looks like:
- **Welcome to JoeDo** with three items suggesting next steps
- **Shopping List** with three items

You can delete both lists once you're done exploring.

## Opening JoeDo

By default JoeDo runs in **Menu Bar Only** mode: no Dock icon, no window opens by default. Look for the small checklist icon in the top-right corner of your Mac's menu bar.

- **Left-click** the menu bar icon: opens a popover with all your lists. Click outside to close.
- **Right-click** the menu bar icon: short menu with Help, Settings, and Quit.

If you prefer a regular app window instead, open Settings and change the mode to Window + Menu Bar (see [Settings](#settings-field-by-field) below).

## Lists

### Home screen

The first thing you see after clicking the menu bar icon is the **Lists** screen. Each row is one of your lists, coloured via the active theme (top of the screen is the most urgent list).

The small number on the right of each row is **done / total** tasks (for example, `2/5` means 2 complete out of 5).

### Create a list
- Click the small **plus** symbol at the top, or
- Press `⌘N` anywhere in JoeDo, or
- Use the trackpad to pinch two fingers apart

A new empty row opens in edit mode. Type the list name, press Enter. If you leave it empty and press Enter or Escape, the row disappears.

### Open a list
Click a list row. The view slides into the list's tasks.

### Rename a list
Right-click the list row and choose **Rename**, or press `⌘R` while the list is selected. Type the new name and press Enter.

### Archive a list
- Swipe the list row right past the blue mark, or
- Right-click the list row and choose **Archive** (or press `⌘E`).

Archived lists are hidden by default. To see them, open Settings and turn on **Show archived lists**. They appear underneath a thin `ARCHIVED` section divider, dimmed and desaturated so you can tell at a glance they're inactive.

To bring one back, right-click and choose **Unarchive**.

### Delete a list
- Swipe the list row left past the red mark, or
- Right-click and choose **Delete**

Deleting a list also deletes all its tasks. You can recover with `⌘Z` (undo) as long as you haven't quit the app.

### Reorder lists
- Hover a list row. A small grip icon appears on the left. Drag it up or down.
- Or right-click a list and use **Move to Top / Move Up / Move Down / Move to Bottom**.

## Tasks

Inside a list you see **your list name** at the top, a `Back` arrow to return home, a small `+` to add tasks, and the tasks themselves.

### Add a task
- Click the `+` at the top, or press `⌘N`, or pinch apart on the trackpad.
- Type the task, press Enter.
- Empty tasks on Enter or Escape disappear.

### Edit a task
Click the task. The text becomes editable. Press Enter to save, Escape to discard.

### Complete a task
- Swipe right past the green mark, or
- Right-click and choose **Mark Complete** (or press `⌘Return`)

Completed tasks stay visible with a strikethrough for a couple of seconds, then automatically drop to the bottom of the list. The completion plays an ascending chime (the pitch depends on how far down the list the task was).

To un-complete: right-click and choose **Mark Incomplete**, or press `⌘Return` again.

### Delete a task
- Swipe left past the red mark, or
- Right-click and choose **Delete** (or press `⌘Backspace`)

Accidental deletion recoverable with `⌘Z`.

### Reorder tasks
- Hover a row, drag the grip on the left up or down.
- Or right-click and use the Move options (shortcuts: `⌥⌘↑`, `⌥⌘↓`, `⇧⌘↑`, `⇧⌘↓`).

### Clear all completed tasks in a list
Press `⇧⌘K` inside a list, or right-click a list on the home screen and choose **Clear Completed**. Every completed task in that list is removed at once.

## Gestures

| Gesture | What it does |
|---|---|
| Swipe row right | Complete the task (or archive a list) |
| Swipe row left | Delete |
| Two-finger trackpad swipe | Same as above (left or right) |
| Hover and drag the grip | Reorder |
| Trackpad pinch apart | Add a new list or task (context-aware) |
| Click the `+` icon | Add a new list or task |
| Click a row | Edit (in a task list) or open (on Home) |
| Right-click a row | Full context menu of options |

## Keyboard shortcuts

### Global (anywhere in JoeDo)
| Shortcut | Action |
|---|---|
| `⌘N` | New list (on Home) or new task (in a list) |
| `⌘F` | Search the current screen |
| `⌘[` | Back to Lists (from inside a list) |
| `⌘Z` / `⇧⌘Z` | Undo / Redo |
| `⇧⌘K` | Clear completed tasks |
| `⌘,` | Open Settings |
| `⌃⌘J` | Quick-add from any app |

### Inside a right-click menu
| Shortcut | Action |
|---|---|
| `⌘Return` | Mark complete / incomplete |
| `⌥⌘↑` / `⌥⌘↓` | Move row up / down |
| `⇧⌘↑` / `⇧⌘↓` | Move row to top / bottom |
| `⌘Backspace` | Delete |
| `⌘R` | Rename (on a list) |
| `⌘E` | Archive / unarchive (on a list) |

## Quick Add from anywhere

Press `⌃⌘J` from any app on your Mac and a small capture window slides in. Type the task, press Enter, and it's added to your top list. The window then disappears.

This is enabled by default. To disable it or to check that it's on, open Settings and look for the Quick Add section.

## Menu bar right-click menu

Right-click the JoeDo checklist icon in the menu bar. You get:

- **Help** opens the comprehensive Help window with every shortcut and gesture reference.
- **Settings** opens the Settings window, positioned directly under the menu bar icon.
- **Quit JoeDo** (`⌘Q`) quits the app.

## Settings, field by field

Open Settings with `⌘,` or via the menu bar right-click. Each section:

### Appearance
**Theme**. Five options:
- **Heatmap** (default). Red at the top, warm yellow at the bottom. The classic heatmap look.
- **Sunset**. Magenta to burnt orange.
- **Night Owl**. Navy to teal.
- **Grass**. Forest green to lime.
- **Ultraviolet**. Deep purple to hot pink.

A live preview slab shows the selected theme applied to five rows. Changing theme re-colours every list and task instantly.

### App Location
Where JoeDo lives:
- **Window + Menu Bar**. Both a regular Dock icon and the menu bar icon are visible. Main window opens on launch.
- **Menu Bar Only** (default). No Dock icon. Access is via the menu bar icon only. Quieter, less visual clutter.

The mode change applies immediately. If you switch to Menu Bar Only while the main window is open, the window closes.

### Sound
**Volume slider**. Controls the loudness of the completion chime, delete swoosh, and add pop. Drag to zero to mute.

### Home
**Show archived lists**. Off by default. Turn on to see archived lists on the home screen, grouped under a thin `ARCHIVED` divider below the active ones and dimmed so you can tell them apart.

### Quick Add
**Global hotkey ⌃⌘J**. On by default. When on, pressing `⌃⌘J` from any app opens a small capture window for jotting down a task. Off removes the global hotkey entirely.

### Data
**Reset All Data**. Deletes every list and task. A confirmation dialog appears to prevent accidents. Cannot be undone.

**Show Welcome Again**. Re-enables the one-time welcome screen for the next app launch. Useful if you want to see it again or share the first-run experience with someone.

## Undo and redo

Every destructive or state-changing action is undoable:
- Creating a list or task
- Deleting a list or task
- Completing or uncompleting a task
- Editing a name
- Reordering

Press `⌘Z` to undo. Press `⇧⌘Z` to redo. Undo history lasts for the current session; quitting the app clears it.

## Troubleshooting

**The menu bar icon disappeared.** You're probably in Window + Menu Bar mode and removed the icon by mistake. Check Settings > App Location and make sure one of the options that shows the menu bar is selected.

**Quick Add shortcut isn't working.** Check that Settings > Quick Add has the toggle on. If another app also uses `⌃⌘J`, there could be a conflict; the first app to register the shortcut wins.

**Welcome image didn't appear, or I want to see it again.** Settings > Data > Show Welcome Again. Next time you launch the app, it'll appear.

**I accidentally deleted something.** Press `⌘Z` to undo. If you've already quit the app, it's gone. Regular backups via Time Machine are the only recovery for data lost before an app restart.

**I want to start fresh.** Settings > Data > Reset All Data. This wipes every list and task. It's permanent.
