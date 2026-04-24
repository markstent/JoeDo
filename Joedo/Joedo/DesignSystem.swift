import SwiftUI

// Central design tokens. Every size, weight, opacity, and spacing value
// should go through here so the look stays consistent as the app grows.
enum DS {

    // MARK: - Typography
    enum Typo {
        /// Big screen titles ("Lists", the current list's name).
        static let display  = Font.system(size: 26, weight: .black,    design: .rounded)
        /// Section titles inside Help / Settings.
        static let section  = Font.system(size: 17, weight: .heavy,    design: .rounded)
        /// The bold coloured task/list row.
        static let row      = Font.system(size: 19, weight: .black,    design: .rounded)
        /// Compact row variant for the menu-bar popover.
        static let rowCompact = Font.system(size: 17, weight: .black,  design: .rounded)
        /// Emphasis label (e.g. the `← Lists` back button).
        static let label    = Font.system(size: 13, weight: .heavy,    design: .rounded)
        /// Readable prose (Help bullets, Settings descriptions).
        static let body     = Font.system(size: 13, weight: .medium,   design: .rounded)
        /// Small secondary text (counts, captions).
        static let caption  = Font.system(size: 12, weight: .semibold, design: .rounded)
        /// Monospace shortcut glyphs.
        static let mono     = Font.system(size: 12, weight: .bold,     design: .monospaced)
    }

    // MARK: - Spacing (4pt base grid)
    enum Space {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 20
        static let xl:  CGFloat = 28
    }

    // MARK: - Row heights
    enum Row {
        static let standard: CGFloat = 56
        static let compact:  CGFloat = 48
        static let header:   CGFloat = 56
        static let addZone:  CGFloat = 36
    }

    // MARK: - Opacity tiers on white text over a tinted window
    enum Tier {
        static let primary:   Double = 1.00
        static let secondary: Double = 0.65
        static let tertiary:  Double = 0.35
        static let ghost:     Double = 0.15
    }

    // MARK: - Backdrops
    enum BG {
        static let window = Color(white: 0.07)
        static let hover  = Color.white.opacity(0.05)
    }

    // MARK: - Corner radii
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
    }

    // MARK: - Motion (single source of truth for timings/springs)
    enum Motion {
        static let quick:    Animation = .easeOut(duration: 0.15)
        static let standard: Animation = .easeInOut(duration: 0.22)
        static let spring:   Animation = .spring(response: 0.30, dampingFraction: 0.72)
        static let slow:     Animation = .easeInOut(duration: 0.40)
    }
}

// Returns the better-contrasting foreground colour for a given background.
// Used so task text on pale-yellow row-bottoms stays readable.
extension Color {
    func preferredForeground() -> Color {
        // Approximate luminance from the Color's resolved NSColor.
        // If we can't resolve, fall back to white.
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.white
        let r = Double(nsColor.redComponent)
        let g = Double(nsColor.greenComponent)
        let b = Double(nsColor.blueComponent)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.72 ? Color.black.opacity(0.88) : Color.white
    }
}
