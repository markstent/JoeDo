import SwiftUI
import SwiftData
import AppKit

// Floating capture panel summoned by the global hotkey. Slides in from
// screen-top-center, focused, dismisses on Enter / Esc / focus loss.
@MainActor
final class QuickAddWindowController: NSObject {
    static let shared = QuickAddWindowController()

    private var panel: NSPanel?
    private var resignObserver: Any?

    private override init() { super.init() }

    func show() {
        ensurePanel()
        position()
        panel?.alphaValue = 0
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        animateIn()
        installResignObserver()
    }

    func hide() {
        animateOut { [weak self] in
            DispatchQueue.main.async {
                self?.panel?.orderOut(nil)
                self?.removeResignObserver()
            }
        }
    }

    // MARK: - Build / layout

    private func ensurePanel() {
        guard panel == nil else { return }

        let hosting = NSHostingView(
            rootView: QuickAddView(
                onSubmit: { [weak self] text in
                    self?.commit(text)
                    self?.hide()
                },
                onDismiss: { [weak self] in self?.hide() }
            )
        )

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 88),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.level = .floating
        p.hidesOnDeactivate = true
        p.isReleasedWhenClosed = false
        p.contentView = hosting
        p.backgroundColor = .clear
        p.isOpaque = false

        panel = p
    }

    private func position() {
        guard let panel, let screen = NSScreen.main else { return }
        let frame = panel.frame
        let origin = NSPoint(
            x: screen.frame.midX - frame.width / 2,
            y: screen.frame.maxY - frame.height - 220
        )
        panel.setFrameOrigin(origin)
    }

    private func animateIn() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
    }

    private func animateOut(completion: @Sendable @escaping () -> Void) {
        guard let panel, panel.isVisible else { completion(); return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        }, completionHandler: completion)
    }

    // Close when another window takes key focus (clicking outside).
    private func installResignObserver() {
        removeResignObserver()
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { _ in
            Task { @MainActor in QuickAddWindowController.shared.hide() }
        }
    }

    private func removeResignObserver() {
        if let token = resignObserver {
            NotificationCenter.default.removeObserver(token)
            resignObserver = nil
        }
    }

    // MARK: - Commit

    private func commit(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let context = ModelContext(JoedoModelStack.container)
        let descriptor = FetchDescriptor<TaskList>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.order)]
        )
        let targetList: TaskList
        if let first = (try? context.fetch(descriptor))?.first {
            targetList = first
        } else {
            targetList = TaskList(title: "Inbox", order: 0)
            context.insert(targetList)
        }
        let minOrder = (targetList.items.map(\.order).min() ?? 0) - 1
        let item = TodoItem(title: trimmed, order: minOrder, list: targetList)
        context.insert(item)
        try? context.save()
    }
}

private struct QuickAddView: View {
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Thin heatmap stripe at the top so it reads as Joedo, not a
            // generic alert panel.
            LinearGradient(
                colors: [Theme.heatmap.color(for: 0, of: 2),
                         Theme.heatmap.color(for: 1, of: 2)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 3)

            HStack(spacing: DS.Space.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.heatmap.color(for: 0, of: 2))
                TextField("Quick add to your top list…", text: $text)
                    .textFieldStyle(.plain)
                    .font(DS.Typo.section)
                    .focused($focused)
                    .onSubmit {
                        let t = text.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty { onSubmit(t) } else { onDismiss() }
                    }
                    .onExitCommand { onDismiss() }
            }
            .padding(.horizontal, DS.Space.lg)
            .frame(maxWidth: .infinity, minHeight: 64)
        }
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        .onAppear { focused = true }
    }
}
