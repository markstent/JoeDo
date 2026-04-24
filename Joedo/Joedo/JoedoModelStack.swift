import SwiftData

// Single source of truth for the SwiftData ModelContainer.
// Exposing it as a shared singleton lets both SwiftUI scenes and AppKit
// code (AppDelegate, the quick-add panel) work against the same store.
@MainActor
enum JoedoModelStack {
    static let container: ModelContainer = {
        let schema = Schema([
            TaskList.self,
            TodoItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
