import SwiftUI
import SwiftData

// Root screen: a NavigationStack whose root is the Lists-of-Lists home.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

    @State private var path: [TaskList] = []

    var body: some View {
        NavigationStack(path: $path) {
            ListsHomeView(onOpenList: { list in path.append(list) })
                .navigationDestination(for: TaskList.self) { list in
                    TaskListView(list: list)
                }
        }
        .background(OpenSettingsBridge())
        .background(OpenHelpBridge())
        .task { modelContext.undoManager = undoManager }
        .onReceive(NotificationCenter.default.publisher(for: .joedoAddNew)) { _ in
            let target: Notification.Name = path.isEmpty
                ? .joedoAddList
                : .joedoAddTaskInCurrent
            NotificationCenter.default.post(name: target, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .joedoGoBack)) { _ in
            if !path.isEmpty { path.removeLast() }
        }
    }
}


extension Notification.Name {
    static let joedoAddNew = Notification.Name("joedoAddNew")
    static let joedoAddList = Notification.Name("joedoAddList")
    static let joedoAddTaskInCurrent = Notification.Name("joedoAddTaskInCurrent")
    static let joedoGoBack = Notification.Name("joedoGoBack")
    static let joedoClearCompletedCurrent = Notification.Name("joedoClearCompletedCurrent")
    static let joedoFocusSearch = Notification.Name("joedoFocusSearch")
    static let joedoOpenSettings = Notification.Name("joedoOpenSettings")
    static let joedoOpenHelp = Notification.Name("joedoOpenHelp")
}

// Zero-size view that bridges AppKit code to SwiftUI's openSettings action.
struct OpenSettingsBridge: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .joedoOpenSettings)) { _ in
                openSettings()
            }
    }
}

// Bridge so AppKit code (menu-bar right-click → Help…) can open the
// Window(id: "help") scene via SwiftUI's openWindow environment action.
struct OpenHelpBridge: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .joedoOpenHelp)) { _ in
                openWindow(id: "help")
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskList.self, TodoItem.self], inMemory: true)
        .frame(width: 480, height: 560)
}
