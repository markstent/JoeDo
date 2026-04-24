import SwiftUI

// Typography helpers. Clear uses a custom rounded display font; we approximate
// with the system's SF Pro Rounded at the heaviest weight ("black") — ships
// with macOS, no licensing concerns, visually very close.
enum Typography {
    static func row(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func title(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}
