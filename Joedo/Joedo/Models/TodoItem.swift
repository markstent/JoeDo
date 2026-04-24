import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var order: Int                // position within list — top row = 0, higher = lower down
    var isCompleted: Bool
    var completedAt: Date?        // `?` = Swift optional (can be nil / absent)
    var dueDate: Date?            // optional reminder (used in Phase 6)
    var repeatRule: String?       // "daily" | "weekly" | nil (Phase 6)
    var list: TaskList?           // back-reference to the list this belongs to

    init(
        title: String,
        order: Int = 0,
        list: TaskList? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.order = order
        self.isCompleted = false
        self.completedAt = nil
        self.dueDate = nil
        self.repeatRule = nil
        self.list = list
    }
}
