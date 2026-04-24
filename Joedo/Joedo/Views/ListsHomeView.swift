import SwiftUI
import SwiftData
import AppKit

struct ListsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.joedoCompact) private var compact
    @Query(sort: \TaskList.order) private var allLists: [TaskList]

    @AppStorage("joedoTheme") private var themeRaw: String = Theme.heatmap.rawValue
    @AppStorage("joedoShowArchived") private var showArchived: Bool = false

    @State private var editingListID: UUID? = nil
    @State private var selectedListID: UUID? = nil
    // The UUID of the list just created — if non-nil, committing its name
    // auto-opens it (so the user doesn't have to click a second time).
    @State private var pendingNewListID: UUID? = nil

    @State private var pinchAccumulator: CGFloat = 0
    @State private var pinchMonitor: Any? = nil

    @State private var searchActive: Bool = false
    @State private var searchText: String = ""
    @FocusState private var searchFieldFocused: Bool

    let onOpenList: (TaskList) -> Void

    private var theme: Theme { Theme(rawValue: themeRaw) ?? .heatmap }

    // Active (non-archived) lists, filtered by search.
    private var activeLists: [TaskList] {
        let base = allLists.filter { !$0.isArchived }
        guard searchActive, !searchText.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // Archived lists, only shown when the user has enabled "Show archived".
    // Still respects search.
    private var archivedLists: [TaskList] {
        guard showArchived else { return [] }
        let base = allLists.filter { $0.isArchived }
        guard searchActive, !searchText.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // Used by selection / reorder to navigate all visible rows.
    private var visibleLists: [TaskList] { activeLists + archivedLists }

    private var headerHeight: CGFloat { compact ? 44 : DS.Row.header }
    private var titleFont: Font {
        compact ? .system(size: 20, weight: .black, design: .rounded) : DS.Typo.display
    }

    var body: some View {
        ZStack {
            DS.BG.window.ignoresSafeArea()
            rowsScroll
        }
        .frame(minWidth: 420, minHeight: 480)
        .onReceive(NotificationCenter.default.publisher(for: .joedoAddList)) { _ in
            addNewList()
        }
        .onAppear { installPinchMonitor() }
        .onDisappear { removePinchMonitor() }
        .onReceive(NotificationCenter.default.publisher(for: .joedoFocusSearch)) { _ in
            searchActive = true
            DispatchQueue.main.async { searchFieldFocused = true }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { selectPrevious(); return .handled }
        .onKeyPress(.downArrow) { selectNext(); return .handled }
        .onKeyPress(.return) {
            if editingListID != nil { return .ignored }
            if let id = selectedListID, let list = visibleLists.first(where: { $0.id == id }) {
                onOpenList(list); return .handled
            }
            return .ignored
        }
        .onKeyPress(.delete) {
            if editingListID != nil { return .ignored }
            if let id = selectedListID, let list = visibleLists.first(where: { $0.id == id }) {
                delete(list); return .handled
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
                    DispatchQueue.main.async { self.addNewList() }
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
                if !visibleLists.isEmpty || !searchText.isEmpty { homeHeader }
                if searchActive { searchBar }
                addZone
                if activeLists.isEmpty && archivedLists.isEmpty {
                    emptyHint
                } else {
                    // Active lists, colored via their own heatmap positions.
                    ForEach(Array(activeLists.enumerated()), id: \.element.id) { index, list in
                        listRow(list,
                                color: theme.color(for: index, of: max(activeLists.count, 1)),
                                index: index,
                                count: activeLists.count,
                                dimmed: false)
                    }
                    // Section divider + archived lists, dimmed.
                    if !archivedLists.isEmpty {
                        archivedSectionHeader
                        ForEach(Array(archivedLists.enumerated()), id: \.element.id) { index, list in
                            listRow(list,
                                    color: theme.color(for: index, of: max(archivedLists.count, 1)),
                                    index: index,
                                    count: archivedLists.count,
                                    dimmed: true)
                        }
                    }
                }
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 240)
                    .contentShape(Rectangle())
                    .onTapGesture { addNewList() }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func listRow(_ list: TaskList,
                         color: Color,
                         index: Int,
                         count: Int,
                         dimmed: Bool) -> some View {
        ListRow(
            list: list,
            color: color,
            isEditing: editingListID == list.id,
            isSelected: selectedListID == list.id && editingListID == nil,
            isFirst: index == 0,
            isLast: index == count - 1,
            onTap: { handleTap(list) },
            onSwipeArchive: { archive(list) },
            onSwipeDelete: { delete(list) },
            onEndEdit: { setEditing(to: nil) },
            onRename: { setEditing(to: list.id) },
            onMoveToTop: { moveToTop(list) },
            onMoveUp: { moveUp(list) },
            onMoveDown: { moveDown(list) },
            onMoveToBottom: { moveToBottom(list) },
            onDropBefore: { sourceID in moveList(sourceID: sourceID, beforeTargetID: list.id) },
            onClearCompleted: { clearCompleted(list) }
        )
        // Desaturate + dim archived rows so they're obviously inactive while
        // still legible.
        .saturation(dimmed ? 0.35 : 1.0)
        .opacity(dimmed ? 0.55 : 1.0)
    }

    // Thin section header between active and archived lists.
    private var archivedSectionHeader: some View {
        HStack(spacing: DS.Space.xs) {
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)
            Text("ARCHIVED")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize()
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
    }

    private var homeHeader: some View {
        Text("Lists")
            .font(titleFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: headerHeight)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.5))
            TextField("Search lists…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(.white.opacity(0.3))
            .frame(maxWidth: .infinity)
            .frame(height: DS.Row.addZone)
            .contentShape(Rectangle())
            .onHover { h in h ? NSCursor.pointingHand.push() : NSCursor.pop() }
            .onTapGesture { addNewList() }
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Text("No lists yet")
                .font(DS.Typo.label)
                .foregroundStyle(.white.opacity(DS.Tier.secondary))
            Text("Top = urgent, bottom = chill. Click + or ⌘N.")
                .font(DS.Typo.caption)
                .foregroundStyle(.white.opacity(DS.Tier.tertiary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.xl)
    }

    // MARK: - Interaction

    private func handleTap(_ list: TaskList) {
        if editingListID == list.id { return }
        if list.title.trimmingCharacters(in: .whitespaces).isEmpty {
            setEditing(to: list.id)
        } else {
            onOpenList(list)
        }
    }

    // MARK: - Edit lifecycle

    private func setEditing(to newID: UUID?) {
        if let oldID = editingListID,
           let old = visibleLists.first(where: { $0.id == oldID }) {
            let trimmed = old.title.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                modelContext.delete(old)
                pendingNewListID = nil
            } else if oldID == pendingNewListID {
                // Newly-named list: auto-open it so the user can start typing
                // tasks without an extra click.
                pendingNewListID = nil
                editingListID = newID
                let listToOpen = old
                DispatchQueue.main.async { onOpenList(listToOpen) }
                return
            }
        }
        editingListID = newID
        if let newID { selectedListID = newID }
    }

    // MARK: - Actions

    private func addNewList() {
        let minOrder = (allLists.map(\.order).min() ?? 0) - 1
        let new = TaskList(title: "", order: minOrder)
        modelContext.insert(new)
        pendingNewListID = new.id
        setEditing(to: new.id)
    }

    private func archive(_ list: TaskList) {
        withAnimation(DS.Motion.quick) { list.isArchived.toggle() }
    }

    private func delete(_ list: TaskList) {
        withAnimation(DS.Motion.standard) { modelContext.delete(list) }
    }

    private func clearCompleted(_ list: TaskList) {
        let toDelete = list.items.filter { $0.isCompleted }
        withAnimation(DS.Motion.standard) {
            for item in toDelete { modelContext.delete(item) }
        }
    }

    // MARK: - Reorder

    private func renumber(_ sorted: [TaskList]) {
        for (i, list) in sorted.enumerated() { list.order = i }
    }

    private func moveToTop(_ list: TaskList) {
        var working = visibleLists
        working.removeAll { $0.id == list.id }
        working.insert(list, at: 0)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    private func moveToBottom(_ list: TaskList) {
        var working = visibleLists
        working.removeAll { $0.id == list.id }
        working.append(list)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    private func moveUp(_ list: TaskList) {
        let sorted = visibleLists
        guard let i = sorted.firstIndex(where: { $0.id == list.id }), i > 0 else { return }
        withAnimation(DS.Motion.quick) {
            let prev = sorted[i - 1]; let swap = prev.order
            prev.order = list.order; list.order = swap
        }
    }

    private func moveDown(_ list: TaskList) {
        let sorted = visibleLists
        guard let i = sorted.firstIndex(where: { $0.id == list.id }), i < sorted.count - 1 else { return }
        withAnimation(DS.Motion.quick) {
            let next = sorted[i + 1]; let swap = next.order
            next.order = list.order; list.order = swap
        }
    }

    private func moveList(sourceID: UUID, beforeTargetID: UUID) {
        guard sourceID != beforeTargetID else { return }
        let sorted = visibleLists
        guard let source = sorted.first(where: { $0.id == sourceID }) else { return }
        var working = sorted
        working.removeAll { $0.id == sourceID }
        let insertAt = working.firstIndex(where: { $0.id == beforeTargetID }) ?? working.count
        working.insert(source, at: insertAt)
        withAnimation(DS.Motion.standard) { renumber(working) }
    }

    // MARK: - Selection

    private func selectNext() {
        let ids = visibleLists.map(\.id)
        guard !ids.isEmpty else { return }
        if let current = selectedListID, let idx = ids.firstIndex(of: current) {
            selectedListID = ids[min(idx + 1, ids.count - 1)]
        } else {
            selectedListID = ids.first
        }
    }

    private func selectPrevious() {
        let ids = visibleLists.map(\.id)
        guard !ids.isEmpty else { return }
        if let current = selectedListID, let idx = ids.firstIndex(of: current) {
            selectedListID = ids[max(idx - 1, 0)]
        } else {
            selectedListID = ids.last
        }
    }
}

// List row wrapper: @Bindable, context menu, drag handle, drop indicator.
private struct ListRow: View {
    @Bindable var list: TaskList
    let color: Color
    let isEditing: Bool
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    var onTap: () -> Void
    var onSwipeArchive: () -> Void
    var onSwipeDelete: () -> Void
    var onEndEdit: () -> Void
    var onRename: () -> Void
    var onMoveToTop: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onMoveToBottom: () -> Void
    var onDropBefore: (UUID) -> Void
    var onClearCompleted: () -> Void

    @State private var hovering = false
    @State private var isDropTargeted: Bool = false

    private var totalCount: Int { list.items.count }
    private var doneCount: Int { list.items.filter(\.isCompleted).count }
    private var hasCompleted: Bool { doneCount > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            RowView(
                title: $list.title,
                color: color,
                isEditing: isEditing,
                isSelected: isSelected,
                allowSwipeRight: false,
                onTap: onTap,
                onSwipeComplete: onSwipeArchive,
                onSwipeDelete: onSwipeDelete,
                onEndEdit: onEndEdit
            )
            .dropDestination(for: String.self, action: { droppedIDs, _ in
                guard let idStr = droppedIDs.first,
                      let sourceID = UUID(uuidString: idStr) else { return false }
                onDropBefore(sourceID)
                return true
            }, isTargeted: { t in
                isDropTargeted = t
            })

            if isDropTargeted {
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(height: 2)
                    .allowsHitTesting(false)
            }

            if totalCount > 0 && !isEditing {
                HStack {
                    Spacer()
                    Text("\(doneCount)/\(totalCount)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.trailing, 20)
                }
                .allowsHitTesting(false)
            }

            HStack {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(hovering ? 0.85 : 0.40))
                    .padding(.leading, 10)
                    .frame(width: 40, height: DS.Row.standard)
                    .contentShape(Rectangle())
                    .onHover { h in
                        hovering = h
                        if h { NSCursor.openHand.push() } else { NSCursor.pop() }
                    }
                    .draggable(list.id.uuidString) {
                        Text(list.title.isEmpty ? "Untitled" : list.title)
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
            Button("Rename", action: onRename).keyboardShortcut("r", modifiers: .command)
            Divider()
            Button("Move to Top", action: onMoveToTop)
                .keyboardShortcut(.upArrow, modifiers: [.command, .shift]).disabled(isFirst)
            Button("Move Up", action: onMoveUp)
                .keyboardShortcut(.upArrow, modifiers: [.command, .option]).disabled(isFirst)
            Button("Move Down", action: onMoveDown)
                .keyboardShortcut(.downArrow, modifiers: [.command, .option]).disabled(isLast)
            Button("Move to Bottom", action: onMoveToBottom)
                .keyboardShortcut(.downArrow, modifiers: [.command, .shift]).disabled(isLast)
            Divider()
            Button(list.isArchived ? "Unarchive" : "Archive", action: onSwipeArchive)
                .keyboardShortcut("e", modifiers: .command)
            Button("Clear Completed", action: onClearCompleted)
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(!hasCompleted)
            Divider()
            Button("Delete", role: .destructive, action: onSwipeDelete)
                .keyboardShortcut(.delete, modifiers: .command)
        }
    }
}
