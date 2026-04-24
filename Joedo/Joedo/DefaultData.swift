import SwiftData

// Seeds starter lists + tasks on first launch (only when the SwiftData
// store is empty). Gives new users something to see and learn from rather
// than an empty home screen.
@MainActor
enum DefaultData {
    static func seedIfEmpty() {
        let context = ModelContext(JoedoModelStack.container)
        let existing = (try? context.fetch(FetchDescriptor<TaskList>()))?.count ?? 0
        guard existing == 0 else { return }

        let welcome = TaskList(title: "Welcome to JoeDo", order: 0)
        context.insert(welcome)
        let welcomeTasks = [
            "Create more lists",
            "Check the settings out",
            "Change App skin",
        ]
        for (i, title) in welcomeTasks.enumerated() {
            context.insert(TodoItem(title: title, order: i, list: welcome))
        }

        let shopping = TaskList(title: "Shopping List", order: 1)
        context.insert(shopping)
        let shoppingTasks = [
            "Chocolate",
            "More Chocolate",
            "Even More Chocolate",
        ]
        for (i, title) in shoppingTasks.enumerated() {
            context.insert(TodoItem(title: title, order: i, list: shopping))
        }

        try? context.save()
    }
}
