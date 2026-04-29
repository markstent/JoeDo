import SwiftUI
import SwiftData
import AppKit

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.joedoCompact) private var compact
    @Bindable var list: TaskList

    @AppStorage("joedoTheme") private var themeRaw: String = Theme.heatmap.rawValue
    @AppStorage("joedoShownSwipeHint") private var shownSwipeHint: Bool = false

    @State private var editingItemID: UUID? = nil
    @State private var selectedItemID: UUID? = nil
    @State private var pinchAccumulator: CGFloat = 0
    @State private var pinchMonitor: Any? = nil
    // Search
    @State private var searchActive: Bool = false
    @State private var searchText: String = ""
    @FocusState private var searchFieldFocused: Bool
    // Swipe hint
    @State private var showSwipeHint: Bool = false
    // All-done sweep
    @State private var sweepProgress: CGFloat = -1.0
    @State private var lastOpenCount: Int? = nil

    private var theme: Theme { Theme(rawValue: themeRaw) ?? .heatmap }

    private var items: [TodoItem] {
        let sorted = list.items.sorted { $0.order < $1.order }
        guard searchActive, !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var openTaskCount: Int {
        list.items.filter { !$0.isCompleted }.count
    }

    private var headerHeight: CGFloat { compact ? 44 : DS.Row.header }
    private var titleFont: Font {
        compact ? DS.Typo.displayCompact : DS.Typo.display
    }

    var body: some View {
        ZStack {
            DS.BG.window.ignoresSafeArea()
            rowsScroll
            sweepOverlay
        }
        .frame(minWidth: 420, minHeight: 480)
        .navigationTitle(list.title.isEmpty ? "Untitled" : list.title)
        .onReceive(NotificationCenter.default.publisher(for: .joedoAddTaskInCurrent)) { _ in
            addNewTopTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: .joedoClearCompletedCurrent)) { _ in
            clearCompleted()
        }
        .onReceive(NotificationCenter.default.publisher(for: .joedoFocusSearch)) { _ in
            searchActive = true
            DispatchQueue.main.async { searchFieldFocused = true }
        }
        .onAppear {
            installPinchMonitor()
            maybeShowSwipeHint()
            lastOpenCount = openTaskCount
        }
        .onDisappear { removePinchMonitor() }
        .onChange(of: openTaskCount) { old, new in
            if let prev = lastOpenCount, prev > 0 && new == 0 && !list.items.isEmpty {
                triggerSweep()
            }
            lastOpenCount = new
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { selectPrevious(); return .handled }
        .onKeyPress(.downArrow) { selectNext(); return .handled }
        .onKeyPress(.return) {
            if editingItemID != nil { return .ignored }
            if let id = selectedItemID { editingItemID = id; return .handled }
            return .ignored
        }
        .onKeyPress(.space) {
            if editingItemID != nil { return .ignored }
            if let id = selectedItemID, let item = list.items.first(where: { $0.id == id }) {
                toggleComplete(item)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.delete) {
            if editingItemID != nil { return .ignored }
            if let id = selectedItemID, let item = list.items.first(where: { $0.id == id }) {
                delete(item)
                return .handled
            }
            return .ignored
        }
    }

    private func installPinchMonitor() {
        guard pinchMonitor == nil else { return }
        pinchMonitor = NSEvent.addLocalMonitorForEvents(matching: [.magnify]) { event in
            switch event.phase {
            case .began: self.pinchAccumulator = 0
            case .changed: self.pinchAccumulator += event.magnification
            case .ended:
                if self.pinchAccumulator > 0.25 {
                    DispatchQueue.main.async { self.addNewTopTask() }
                }
                self.pinchAccumulator = 0
            default: break
            }
            return event
        }
    }

    private func removePinchMonitor() {
        if let monitor = pinchMonitor { NSEvent.removeMonitor(monitor); pinchMonitor = nil }
    }

    // MARK: - Scroll content

    private var rowsScroll: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: 28)
                listHeader
                if showSwipeHint { swipeHintBanner.transition(.opacity) }
                if searchActive { searchBar }
                addZone
                if items.isEmpty {
                    emptyHint
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        TaskRow(
                            item: item,
                            color: theme.color(for: index, of: items.count),
                            isEditing: editingItemID == item.id,
                            isSelected: selectedItemID == item.id && editingItemID == nil,
                            isFirst: index == 0,
                            isLast: index == items.count - 1,
                            onTap: { startEditing(item) },
                            onSwipeComplete: { toggleComplete(item) },
                            onSwipeDelete: { delete(item) },
                            onEndEdit: { endEditing() },
                            onMoveToTop: { moveToTop(item) },
                            onMoveUp: { moveUp(item) },
                            onMoveDown: { moveDown(item) },
                            onMoveToBottom: { moveToBottom(item) },
                            onDropBefore: { sourceID in moveItem(sourceID: sourceID, beforeTargetID: item.id) }
                        )
                    }
                }
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 240)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Pieces

    private var listHeader: some View {
        ZStack {
            Text(list.title.isEmpty ? "Untitled" : list.title)
                .font(titleFont)
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 80)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(DS.Typo.label)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(DS.Tier.secondary))
                .help("Back to Lists")
                .onHover { h in h ? NSCursor.pointingHand.push() : NSCursor.pop() }
                .accessibilityLabel("Back to lists")
                Spacer()
            }
            .padding(.horizontal, DS.Space.md)
        }
        .frame(height: headerHeight)
    }

    private var swipeHintBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw.fill")
            Text("Tip: swipe a row right to complete, left to delete.")
        }
        .font(DS.Typo.caption)
        .foregroundStyle(.white.opacity(0.55))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            TextField("Search tasks…", text: $searchText)
                .textFieldStyle(.plain)
                .font(DS.Typo.search)
                .foregroundStyle(.white)
                .focused($searchFieldFocused)
                .onExitCommand { searchActive = false; searchText = "" }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var addZone: some View {
        Image(systemName: "plus")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white.opacity(0.3))
            .frame(maxWidth: .infinity)
            .frame(height: DS.Row.addZone)
            .contentShape(Rectangle())
            .onHover { h in h ? NSCursor.pointingHand.push() : NSCursor.pop() }
            .onTapGesture { addNewTopTask() }
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Text("No tasks yet")
                .font(DS.Typo.label)
                .foregroundStyle(.white.opacity(DS.Tier.secondary))
            Text("Top = urgent, bottom = chill. Click + or ⌘N.")
                .font(DS.Typo.caption)
                .foregroundStyle(.white.opacity(DS.Tier.tertiary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.xl)
    }

    @ViewBuilder
    private var sweepOverlay: some View {
        if sweepProgress >= 0 {
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.25), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.45)
                .offset(x: -geo.size.width * 0.5 + sweepProgress * geo.size.width * 2.0)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Edit lifecycle

    private func setEditing(to newID: UUID?) {
        if let oldID = editingItemID,
           let old = items.first(where: { $0.id == oldID }),
           old.title.trimmingCharacters(in: .whitespaces).isEmpty {
            modelContext.delete(old)
        }
        editingItemID = newID
        if let newID { selectedItemID = newID }
    }
    private func startEditing(_ item: TodoItem) { setEditing(to: item.id) }
    private func endEditing() { setEditing(to: nil) }

    // MARK: - Actions

    private func addNewTopTask() {
        let minOrder = (list.items.map(\.order).min() ?? 0) - 1
        let new = TodoItem(title: "", order: minOrder, list: list)
        modelContext.insert(new)
        setEditing(to: new.id)
        AudioController.shared.playAdd()
    }

    private func toggleComplete(_ item: TodoItem) {
        let position = items.firstIndex(where: { $0.id == item.id }) ?? 0
        let willComplete = !item.isCompleted
        withAnimation(DS.Motion.quick) {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
        }
        if willComplete {
            AudioController.shared.playComplete(position: position)
            // Auto-sink to bottom after a brief delay, if still completed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard item.isCompleted else { return }
                sinkCompletedToBottom(item)
            }
        }
    }

    private func sinkCompletedToBottom(_ item: TodoItem) {
        let sorted = list.items.sorted { $0.order < $1.order }
        guard let idx = sorted.firstIndex(where: { $0.id == item.id }) else { return }
        guard idx < sorted.count - 1 else { return }
        var working = sorted
        working.removeAll { $0.id == item.id }
        working.append(item)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    private func delete(_ item: TodoItem) {
        AudioController.shared.playDelete()
        withAnimation(DS.Motion.standard) { modelContext.delete(item) }
    }

    private func clearCompleted() {
        let toDelete = list.items.filter { $0.isCompleted }
        guard !toDelete.isEmpty else { return }
        withAnimation(DS.Motion.standard) {
            for item in toDelete { modelContext.delete(item) }
        }
    }

    // MARK: - Reorder

    private func renumber(_ sorted: [TodoItem]) {
        for (i, item) in sorted.enumerated() { item.order = i }
    }

    private func moveToTop(_ item: TodoItem) {
        var working = list.items.sorted { $0.order < $1.order }
        working.removeAll { $0.id == item.id }
        working.insert(item, at: 0)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    private func moveToBottom(_ item: TodoItem) {
        var working = list.items.sorted { $0.order < $1.order }
        working.removeAll { $0.id == item.id }
        working.append(item)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    private func moveUp(_ item: TodoItem) {
        let sorted = list.items.sorted { $0.order < $1.order }
        guard let i = sorted.firstIndex(where: { $0.id == item.id }), i > 0 else { return }
        withAnimation(DS.Motion.quick) {
            let prev = sorted[i - 1]; let swap = prev.order
            prev.order = item.order; item.order = swap
        }
    }

    private func moveDown(_ item: TodoItem) {
        let sorted = list.items.sorted { $0.order < $1.order }
        guard let i = sorted.firstIndex(where: { $0.id == item.id }), i < sorted.count - 1 else { return }
        withAnimation(DS.Motion.quick) {
            let next = sorted[i + 1]; let swap = next.order
            next.order = item.order; item.order = swap
        }
    }

    private func moveItem(sourceID: UUID, beforeTargetID: UUID) {
        guard sourceID != beforeTargetID else { return }
        let sorted = list.items.sorted { $0.order < $1.order }
        guard let source = sorted.first(where: { $0.id == sourceID }) else { return }
        var working = sorted
        working.removeAll { $0.id == sourceID }
        let insertAt = working.firstIndex(where: { $0.id == beforeTargetID }) ?? working.count
        working.insert(source, at: insertAt)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    // MARK: - Selection helpers

    private func selectNext() {
        let ids = items.map(\.id)
        guard !ids.isEmpty else { return }
        if let current = selectedItemID, let idx = ids.firstIndex(of: current) {
            selectedItemID = ids[min(idx + 1, ids.count - 1)]
        } else {
            selectedItemID = ids.first
        }
    }

    private func selectPrevious() {
        let ids = items.map(\.id)
        guard !ids.isEmpty else { return }
        if let current = selectedItemID, let idx = ids.firstIndex(of: current) {
            selectedItemID = ids[max(idx - 1, 0)]
        } else {
            selectedItemID = ids.last
        }
    }

    // MARK: - One-off hints + celebrations

    private func maybeShowSwipeHint() {
        guard !shownSwipeHint else { return }
        guard !items.isEmpty else { return }
        withAnimation(DS.Motion.standard) { showSwipeHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(DS.Motion.standard) { showSwipeHint = false }
            shownSwipeHint = true
        }
    }

    private func triggerSweep() {
        sweepProgress = -1
        withAnimation(.linear(duration: 0.6)) { sweepProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            sweepProgress = -1
        }
    }
}

// Task row wrapper with context menu + drag handle.
private struct TaskRow: View {
    @Bindable var item: TodoItem
    let color: Color
    let isEditing: Bool
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    var onTap: () -> Void
    var onSwipeComplete: () -> Void
    var onSwipeDelete: () -> Void
    var onEndEdit: () -> Void
    var onMoveToTop: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onMoveToBottom: () -> Void
    var onDropBefore: (UUID) -> Void

    @State private var hovering = false
    @State private var isDropTargeted: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            RowView(
                title: $item.title,
                color: color,
                isCompleted: item.isCompleted,
                isEditing: isEditing,
                isSelected: isSelected,
                onTap: onTap,
                onSwipeRight: onSwipeComplete,
                onSwipeLeft: onSwipeDelete,
                onEndEdit: onEndEdit
            )
            .dropDestination(for: String.self, action: { droppedIDs, _ in
                guard let idStr = droppedIDs.first,
                      let sourceID = UUID(uuidString: idStr) else { return false }
                onDropBefore(sourceID)
                return true
            }, isTargeted: { isTargeted in
                isDropTargeted = isTargeted
            })

            // Drop-target indicator line along the top edge.
            if isDropTargeted {
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(height: 2)
                    .allowsHitTesting(false)
            }

            // Drag grip — sibling of RowView so its .draggable doesn't
            // collide with the row's swipe DragGesture.
            HStack {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(hovering ? 0.85 : 0.40))
                    .padding(.leading, 10)
                    .frame(width: 40, height: DS.Row.standard)
                    .contentShape(Rectangle())
                    .onHover { h in
                        hovering = h
                        if h { NSCursor.openHand.push() } else { NSCursor.pop() }
                    }
                    .draggable(item.id.uuidString) {
                        Text(item.title.isEmpty ? "Untitled" : item.title)
                            .font(DS.Typo.row)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                            .frame(width: 240, height: DS.Row.standard)
                            .background(color)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                Spacer()
            }
        }
        .contextMenu {
            Button(item.isCompleted ? "Mark Incomplete" : "Mark Complete", action: onSwipeComplete)
                .keyboardShortcut(.return, modifiers: .command)
            Divider()
            Button("Move to Top", action: onMoveToTop)
                .keyboardShortcut(.upArrow, modifiers: [.command, .shift])
                .disabled(isFirst)
            Button("Move Up", action: onMoveUp)
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
                .disabled(isFirst)
            Button("Move Down", action: onMoveDown)
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
                .disabled(isLast)
            Button("Move to Bottom", action: onMoveToBottom)
                .keyboardShortcut(.downArrow, modifiers: [.command, .shift])
                .disabled(isLast)
            Divider()
            Button("Delete", role: .destructive, action: onSwipeDelete)
                .keyboardShortcut(.delete, modifiers: .command)
        }
    }
}
