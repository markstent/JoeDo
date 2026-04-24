import SwiftUI

// Tighter wrapper around ContentView for the menu-bar popover. Same
// underlying NavigationStack + data, just a smaller header and tighter
// row height so a 440×560 popover doesn't feel shouty.
struct CompactContentView: View {
    var body: some View {
        ContentView()
            .environment(\.joedoCompact, true)
    }
}

private struct JoedoCompactKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var joedoCompact: Bool {
        get { self[JoedoCompactKey.self] }
        set { self[JoedoCompactKey.self] = newValue }
    }
}
