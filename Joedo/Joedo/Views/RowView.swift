import SwiftUI

// A single full-bleed, flat-colored row.
struct RowView: View {
    @Binding var title: String
    let color: Color
    var isCompleted: Bool = false
    var isEditing: Bool = false
    var isSelected: Bool = false

    var allowSwipeRight: Bool = true
    var allowSwipeLeft: Bool = true

    var onTap: () -> Void = {}
    var onSwipeComplete: () -> Void = {}
    var onSwipeDelete: () -> Void = {}
    var onEndEdit: () -> Void = {}

    @Environment(\.joedoCompact) private var compact
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragX: CGFloat = 0
    @State private var hovering: Bool = false
    @FocusState private var fieldFocused: Bool

    private let swipeThreshold: CGFloat = 80
    // Maximum the row can be dragged even if the user keeps pulling.
    // After the threshold, drag is tapered exponentially — iOS-style
    // rubber-band feel rather than flying off.
    private let swipeMax: CGFloat = 140

    private var rowHeight: CGFloat { compact ? DS.Row.compact : DS.Row.standard }
    private var rowFont: Font { compact ? DS.Typo.rowCompact : DS.Typo.row }
    private var foreground: Color { color.preferredForeground() }

    var body: some View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.isEmpty ? "Untitled row" : title)
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Click to edit. Swipe right to complete. Swipe left to delete.")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backdrop: some View {
        ZStack {
            if allowSwipeRight {
                ZStack(alignment: .leading) {
                    Color.green
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.leading, 24)
                }
                .opacity(dragX > 0 ? min(1, dragX / swipeThreshold) : 0)
            }

            if allowSwipeLeft {
                ZStack(alignment: .trailing) {
                    Color.red
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.trailing, 24)
                }
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
                if v > swipeThreshold, allowSwipeRight { onSwipeComplete() }
                else if v < -swipeThreshold, allowSwipeLeft { onSwipeDelete() }
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
}
