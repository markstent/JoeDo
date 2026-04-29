import SwiftUI
import AppKit

// A single full-bleed, flat-colored row.
struct RowView: View {
    @Binding var title: String
    let color: Color
    var isCompleted: Bool = false
    var isEditing: Bool = false
    var isSelected: Bool = false

    var allowSwipeRight: Bool = true
    var allowSwipeLeft: Bool = true

    var rightBackdropColor: Color = .green
    var leftBackdropColor: Color = .red

    var onTap: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    var onSwipeLeft: () -> Void = {}
    var onEndEdit: () -> Void = {}

    @Environment(\.joedoCompact) private var compact
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragX: CGFloat = 0
    @State private var hovering: Bool = false
    @FocusState private var fieldFocused: Bool
    @State private var scrollCtx = ScrollCtx()

    private let swipeThreshold: CGFloat = 80
    // Maximum the row can be dragged even if the user keeps pulling.
    // After the threshold, drag is tapered exponentially — iOS-style
    // rubber-band feel rather than flying off.
    private let swipeMax: CGFloat = 140

    private var rowHeight: CGFloat { compact ? DS.Row.compact : DS.Row.standard }
    private var rowFont: Font { compact ? DS.Typo.rowCompact : DS.Typo.row }
    private var foreground: Color { color.preferredForeground() }

    var body: some View {
        let _ = syncScrollCtx()
        ZStack {
            backdrop
            slab.offset(x: dragX)
                .scaleEffect(reduceMotion ? 1.0 : (abs(dragX) > 2 ? 0.985 : 1.0),
                             anchor: .center)
        }
        .frame(height: rowHeight)
        .clipped()
        .contentShape(Rectangle())
        .overlay(selectionRing)
        .highPriorityGesture(swipeGesture)
        .onTapGesture { if !isEditing { onTap() } }
        .onHover { h in
            hovering = h
            if h && !isEditing { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .task(id: isEditing) {
            try? await Task.sleep(nanoseconds: 40_000_000)
            fieldFocused = isEditing
        }
        .background(ScrollCoordView(ctx: scrollCtx))
        .onAppear { installScrollMonitor() }
        .onDisappear { removeScrollMonitor() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.isEmpty ? "Untitled row" : title)
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Click to edit. Swipe left or right to act.")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backdrop: some View {
        ZStack {
            if allowSwipeRight {
                rightBackdropColor
                    .opacity(dragX > 0 ? min(1, dragX / swipeThreshold) : 0)
            }
            if allowSwipeLeft {
                leftBackdropColor
                    .opacity(dragX < 0 ? min(1, -dragX / swipeThreshold) : 0)
            }
        }
    }

    @ViewBuilder
    private var slab: some View {
        ZStack {
            color
            // Subtle white overlay signalling "I am currently the edited row".
            if isEditing { Color.white.opacity(0.08) }
            // Hover highlight (skipped during edit; the edit tint takes over).
            if hovering && !isEditing { Color.white.opacity(0.06) }

            if isEditing {
                TextField("", text: $title)
                    .textFieldStyle(.plain)
                    .font(rowFont)
                    .foregroundStyle(foreground)
                    .focused($fieldFocused)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Space.lg)
                    .onSubmit { onEndEdit() }
                    .onExitCommand { onEndEdit() }
            } else {
                Text(title.isEmpty ? " " : title)
                    .font(rowFont)
                    .foregroundStyle(foreground)
                    // Full-opacity strikethrough in the contrast-aware
                    // foreground — visible on every heatmap row.
                    .strikethrough(isCompleted, color: foreground)
                    .opacity(isCompleted ? 0.55 : 1.0)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.45), lineWidth: 2)
                .padding(1)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                guard !isEditing else { return }
                let raw = value.translation.width
                // Direction-aware clamp.
                if raw > 0 && !allowSwipeRight { return }
                if raw < 0 && !allowSwipeLeft { return }
                dragX = taperedDrag(raw)
            }
            .onEnded { value in
                let v = value.translation.width
                withAnimation(reduceMotion ? DS.Motion.quick : DS.Motion.spring) {
                    dragX = 0
                }
                if v > swipeThreshold, allowSwipeRight { onSwipeRight() }
                else if v < -swipeThreshold, allowSwipeLeft { onSwipeLeft() }
            }
    }

    // Rubber-band: 1:1 up to threshold, then tapers asymptotically to swipeMax.
    private func taperedDrag(_ raw: CGFloat) -> CGFloat {
        if abs(raw) <= swipeThreshold { return raw }
        let sign: CGFloat = raw < 0 ? -1 : 1
        let over = abs(raw) - swipeThreshold
        let eased = (swipeMax - swipeThreshold) * (1 - exp(-over / 40))
        return sign * (swipeThreshold + eased)
    }

    // MARK: - Two-finger trackpad swipe

    private func syncScrollCtx() {
        scrollCtx.isEditing = isEditing
        scrollCtx.allowRight = allowSwipeRight
        scrollCtx.allowLeft = allowSwipeLeft
        scrollCtx.threshold = swipeThreshold
        scrollCtx.reduceMotion = reduceMotion
        scrollCtx.onRight = onSwipeRight
        scrollCtx.onLeft = onSwipeLeft
    }

    private func installScrollMonitor() {
        guard scrollCtx.monitor == nil else { return }
        scrollCtx.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [self, scrollCtx] event in
            guard event.hasPreciseScrollingDeltas else { return event }
            guard !scrollCtx.isEditing else { return event }
            guard let cv = scrollCtx.coordView, cv.window != nil else { return event }
            let loc = cv.convert(event.locationInWindow, from: nil)
            guard cv.bounds.contains(loc) else { return event }

            if event.momentumPhase != [] {
                return scrollCtx.handledLast ? nil : event
            }

            let dx = event.scrollingDeltaX
            let dy = event.scrollingDeltaY

            switch event.phase {
            case .began:
                scrollCtx.accumulator = 0
                scrollCtx.locked = false
                scrollCtx.handledLast = false
            case .changed:
                if !scrollCtx.locked && abs(dy) > abs(dx) * 1.2 {
                    return event
                }

                scrollCtx.accumulator += dx

                if !scrollCtx.locked && abs(scrollCtx.accumulator) > 6 {
                    scrollCtx.locked = true
                }

                if scrollCtx.locked {
                    if scrollCtx.accumulator > 0 && !scrollCtx.allowRight {
                        scrollCtx.accumulator = 0; scrollCtx.locked = false; return event
                    }
                    if scrollCtx.accumulator < 0 && !scrollCtx.allowLeft {
                        scrollCtx.accumulator = 0; scrollCtx.locked = false; return event
                    }
                    scrollCtx.handledLast = true
                    dragX = taperedDrag(scrollCtx.accumulator)
                    return nil
                }
            case .ended, .cancelled:
                if scrollCtx.locked {
                    let acc = scrollCtx.accumulator
                    withAnimation(scrollCtx.reduceMotion ? DS.Motion.quick : DS.Motion.spring) {
                        dragX = 0
                    }
                    if acc > scrollCtx.threshold, scrollCtx.allowRight { scrollCtx.onRight() }
                    else if acc < -scrollCtx.threshold, scrollCtx.allowLeft { scrollCtx.onLeft() }
                }
                scrollCtx.accumulator = 0
                scrollCtx.locked = false
            default:
                break
            }

            return event
        }
    }

    private func removeScrollMonitor() {
        if let m = scrollCtx.monitor { NSEvent.removeMonitor(m); scrollCtx.monitor = nil }
    }
}

private final class ScrollCtx {
    var monitor: Any?
    weak var coordView: NSView?
    var accumulator: CGFloat = 0
    var locked: Bool = false
    var handledLast: Bool = false
    var isEditing: Bool = false
    var allowRight: Bool = true
    var allowLeft: Bool = true
    var threshold: CGFloat = 80
    var reduceMotion: Bool = false
    var onRight: () -> Void = {}
    var onLeft: () -> Void = {}
}

// Transparent background view that provides coordinate-space access for
// the scroll monitor. Returns nil from hitTest so it never intercepts
// clicks, drags, or any other user interaction.
private struct ScrollCoordView: NSViewRepresentable {
    let ctx: ScrollCtx

    func makeNSView(context: Context) -> NSView {
        let v = HitTransparentView()
        ctx.coordView = v
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        ctx.coordView = nsView
    }
}

private final class HitTransparentView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
