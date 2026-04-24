import SwiftUI

// Heatmap gradient used to color rows. Row position within a list determines
// its color — top rows (most urgent) are at the `top` endpoint; bottom rows
// at the `bottom` endpoint. Interpolation is done in HSB space so hues sweep
// naturally instead of muddying through RGB mid-tones.
enum Theme: String, CaseIterable, Identifiable {
    case heatmap
    case sunset
    case nightOwl
    case grass
    case ultraviolet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heatmap:     return "Heatmap"
        case .sunset:      return "Sunset"
        case .nightOwl:    return "Night Owl"
        case .grass:       return "Grass"
        case .ultraviolet: return "Ultraviolet"
        }
    }

    func color(for index: Int, of count: Int) -> Color {
        guard count > 0 else { return top.color }
        let t: Double = count == 1 ? 0 : min(1, max(0, Double(index) / Double(count - 1)))
        let a = top
        let b = bottom
        return Color(
            hue: a.h + (b.h - a.h) * t,
            saturation: a.s + (b.s - a.s) * t,
            brightness: a.v + (b.v - a.v) * t
        )
    }

    private var top: Endpoint {
        switch self {
        case .heatmap:     return Endpoint(hex: 0xC8201B)  // deep red
        case .sunset:      return Endpoint(hex: 0xD83178)  // magenta
        case .nightOwl:    return Endpoint(hex: 0x1F3A68)  // navy
        case .grass:       return Endpoint(hex: 0x1F6B2E)  // forest green
        case .ultraviolet: return Endpoint(hex: 0x4E1A8A)  // deep purple
        }
    }

    private var bottom: Endpoint {
        switch self {
        // Slightly darker amber-yellow so white row text stays legible.
        case .heatmap:     return Endpoint(hex: 0xE59A14)  // deep amber
        case .sunset:      return Endpoint(hex: 0xF28622)  // burnt orange
        case .nightOwl:    return Endpoint(hex: 0x2DBFA3)  // teal
        // Deeper lime for better contrast with white text.
        case .grass:       return Endpoint(hex: 0x96BE35)  // deeper lime
        case .ultraviolet: return Endpoint(hex: 0xEF2EA3)  // hot pink
        }
    }
}

private struct Endpoint {
    let h: Double
    let s: Double
    let v: Double

    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        let (h, s, v) = Endpoint.rgbToHsb(r: r, g: g, b: b)
        self.h = h; self.s = s; self.v = v
    }

    var color: Color { Color(hue: h, saturation: s, brightness: v) }

    private static func rgbToHsb(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let v = maxC
        let s = maxC == 0 ? 0 : delta / maxC

        var h: Double = 0
        if delta != 0 {
            if maxC == r { h = ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if maxC == g { h = (b - r) / delta + 2 }
            else { h = (r - g) / delta + 4 }
            h /= 6
            if h < 0 { h += 1 }
        }
        return (h, s, v)
    }
}
