# Phase 1 — Creating the Xcode project

This is the one step you need to do in the Xcode GUI. After this, I'll write all the Swift code. Should take ~3 minutes.

## Step-by-step

### 1. Open Xcode

Launch Xcode from `/Applications/Xcode.app` (or Spotlight: ⌘Space, type "Xcode", Enter).

### 2. Start a new project

On the Xcode welcome screen:
- Click **"Create New Project…"**

*(If you don't see the welcome screen, use the menu: **File → New → Project…**, shortcut `⌘⇧N`.)*

### 3. Choose the template

A window appears titled **"Choose a template for your new project"**.

- At the top, click the **macOS** tab.
- Under the **Application** section, click **App**.
- Click **Next**.

### 4. Fill in the project options

You'll see a form. Set exactly these values:

| Field | Value |
|---|---|
| **Product Name** | `Joedo` |
| **Team** | None *(leave blank — you don't need an Apple Developer account for personal use)* |
| **Organization Identifier** | `com.markstent` |
| **Bundle Identifier** | *(auto-fills to `com.markstent.Joedo` — leave it)* |
| **Interface** | `SwiftUI` |
| **Language** | `Swift` |
| **Storage** | **`SwiftData`** ← important, not "None" |
| **Host in CloudKit** | **unchecked** *(we're local-only)* |
| **Include Tests** | your choice — leave **unchecked** for now to keep it simple |

Click **Next**.

### 5. Choose where to save

Xcode now asks where to put the project folder.

- Navigate to: **`/Users/mark.stent/Projects/python/2026/todo_list/`**
- **Uncheck** "Create Git repository on my Mac" *(this folder isn't a git repo; we'll add that later if needed)*
- Click **Create**

### 6. What you should see

Xcode opens your new project. The left sidebar (called the **Project Navigator**) shows a tree that looks roughly like this:

```
Joedo
├── Joedo
│   ├── JoedoApp.swift          ← the @main app entry point
│   ├── ContentView.swift       ← the initial view
│   ├── Item.swift              ← a SwiftData @Model sample
│   ├── Assets.xcassets
│   └── Joedo.entitlements
└── Products
    └── Joedo.app               (grey/red — not built yet)
```

If `Item.swift` is missing (Xcode's SwiftData template sometimes skips it), that's fine — I'll create the models for you anyway.

### 7. Do a quick test run

Let's confirm it compiles before moving on:

- At the top of the Xcode window, near the play/stop buttons, make sure the scheme selector says **"Joedo"** with **"My Mac"** as the destination.
- Press the **▶ Play** button (or `⌘R`).

First build takes ~30 seconds. A tiny Mac window should appear showing the boilerplate SwiftData sample (probably a list of timestamps with a "+" button).

If it launches, Xcode is working. Press the **⏹ Stop** button (or `⌘.`) to quit the app.

### 8. Tell me when you're here

Once step 7 works — the sample app launched and then you stopped it — let me know by saying "**done**" or "**project open**". I'll take over from there and:

1. Replace the sample model with our `TaskList` and `TodoItem` SwiftData models.
2. Replace the sample view with a basic add/delete list of tasks.
3. Verify persistence (add tasks, quit, relaunch, tasks are still there).

That'll complete Phase 1. Then Phase 2 makes it look like Clear.

## If something goes wrong

- **"Team" shows a red error** → it's fine, leave it as None. The error just means the app can't be distributed via the App Store. You're not doing that.
- **Build fails with a signing error** → In Xcode, click the **Joedo** project at the top of the sidebar → **Signing & Capabilities** tab → **Team: None** → **Signing Certificate: Sign to Run Locally**. That's enough for local dev.
- **Something else** → paste the error message back to me and I'll decode it.
