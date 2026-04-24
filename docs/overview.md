# Joedo — Overview

**Joedo** is a minimalist todo app for macOS, modelled on the iOS app *Clear* (useclear.com). Built for personal use, installed from a DMG, stored entirely on your own Mac.

## What it is, in one sentence

A distraction-free list-maker where every task is a full-width slab of colour — no buttons, no menus, just gestures.

## What you'll see

### The three screens

1. **Lists of Lists (Home)** — your collection of lists (e.g. "Groceries", "Work", "Weekend"), each shown as one coloured row.
2. **A List** — the tasks inside one list, stacked top to bottom.
3. **Settings** — a hidden panel (press `⌘,`) for themes, sounds, and text size.

That's it. No sidebars, no toolbars, no search bar, no preferences menu at the top.

### The window

- **No title bar.** The traffic-light buttons (close / min / max) float faintly over the content.
- **Edge-to-edge colour.** Rows fill the window completely. No gaps, no dividers.
- **Bold white text** on each row. Short, clean, readable from across the room.

## Colours

The core idea: **position = priority**. The top row is the most urgent; the bottom is the least. The colour gradient reflects that. Five themes ship on day one:

| Theme | Top colour (urgent) | Bottom colour (chill) | Mood |
|---|---|---|---|
| **Heatmap** *(default)* | Deep red | Warm yellow | The classic Clear-inspired look |
| **Sunset** | Magenta | Burnt orange | Warm, cinematic |
| **Night Owl** | Navy blue | Teal | Dark-mode friendly |
| **Grass** | Forest green | Lime | Fresh, calm |
| **Ultraviolet** | Deep purple | Hot pink | Bold, playful |

Each list can have its own theme.

## Typography

**SF Pro Rounded, Black weight** — the heaviest, friendliest version of the system font that ships with macOS. Large (around 24pt), white, centre-aligned on each row. Nothing else competes for your eye.

## Features (what you can actually do)

### The essentials
- Create lists, rename lists, delete lists.
- Add tasks, edit tasks, complete tasks, delete tasks.
- Reorder tasks — just drag them. The colours recompute automatically based on the new order.
- Archive old lists (hide them without deleting) and bring them back later.

### The feel
- **Sounds.** A satisfying ascending chime when you complete a task — each position in the list plays a slightly higher note, so clearing a whole list sounds like a little melody. A soft swoosh when you delete. A gentle pop when you add.
- **Undo.** Anything you do can be undone with `⌘Z`. Anything.
- **Share a list as an image.** `⌘⇧S` saves a PNG of your current list — great for sending your shopping list to a partner.
- **Reminders.** Optionally attach a due date to any task. macOS will notify you. No servers, no accounts, no Google/Apple calendar linking required.
- **Repeating tasks.** Mark a task as daily or weekly; when you complete it, a fresh copy reappears.

### Convenience
- Keyboard shortcuts: `⌥1` through `⌥9` jump to your first nine lists.
- Esc dismisses any open editor.
- Just start typing when a list is focused to add a new task.
- Pull the list down past the top to add a task at the top; pull up past the bottom to add at the end.

## How you interact

Like Clear, Joedo ditches buttons entirely. Everything is a gesture.

| Gesture | What it does |
|---|---|
| **Swipe right** on a row | Complete the task (check it off) |
| **Swipe left** on a row | Delete the task |
| **Click** a row | Edit it |
| **Pinch two rows apart** | Insert a new task between them |
| **Pinch the whole list closed** | Go back up a level |
| **Pull down past the top** | Add a new task at the top |
| **Long-press and drag** | Reorder |

*(Swipe and pinch work naturally on a MacBook trackpad or Magic Trackpad. If you're on a regular mouse, click-and-drag the row left or right for swipe — pinch needs a trackpad.)*

## What it sounds like

Three bundled sound effects, all understated:

- **Complete** — a short musical note, ascending in pitch for each position down the list. Completing a full list plays a little arpeggio.
- **Delete** — a gentle downward swoosh.
- **Add** — a soft pop.

All of them can be muted or volume-adjusted in Settings.

## What it doesn't do (deliberate)

To keep it simple and free, these are **not** included:

- No sync between devices (stays on this one Mac).
- No accounts, no sign-ups, no cloud.
- No subscription, no shop, no collectible cosmetics.
- No iPhone, iPad, or Apple Watch companion.
- No Spotlight search integration.
- No widgets on the desktop or lock screen.
- No integration with Apple Reminders, Calendar, or third-party services.

If any of these become missed, they can be added later.

## How you'll install it

1. You'll end up with a single file: `Joedo.dmg`.
2. Double-click it — a window opens showing the app icon next to an Applications folder shortcut.
3. Drag the icon into Applications.
4. The very first time you launch, macOS will say it can't verify the developer (because the app isn't signed by Apple — it's just for you). Right-click the app and choose "Open", then click "Open" on the prompt. You only do this once.
5. The app launches to an empty Lists home, ready for your first list.

No installer, no uninstaller, no background processes. To remove, just drag `Joedo.app` to the Trash.

## Status

Planned, not yet built. Build proceeds in 7 phases (see `plan.md`), each independently verifiable on the Mac before moving on:

1. Data skeleton
2. Visual identity
3. Core gestures
4. Pinch gestures
5. Lists-of-lists hierarchy
6. Polish (sounds, undo, themes, reminders, share-as-image)
7. DMG packaging

First runnable (but ugly) version lands after phase 1. First version that *looks* Clear-like lands after phase 2. First version that *feels* Clear-like lands after phase 3.
