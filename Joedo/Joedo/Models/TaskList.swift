import Foundation
import SwiftData

// @Model turns this class into a SwiftData-persisted entity.
// SwiftData auto-generates schema, storage, CRUD — no boilerplate.
@Model
final class TaskList {
    var id: UUID
    var title: String
    var order: Int           // position of this list among all lists (top = lowest number)
    var theme: String        // raw value of Theme enum (introduced in Phase 2)
    var isArchived: Bool
    var createdAt: Date

    // `.cascade` means: delete a list → SwiftData deletes its items too.
    // `inverse:` pairs this with TodoItem.list so SwiftData knows they're the same link.
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(
        title: String,
        order: Int = 0,
        theme: String = "heatmap",
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.order = order
        self.theme = theme
        self.isArchived = isArchived
        self.createdAt = Date()
    }
}
