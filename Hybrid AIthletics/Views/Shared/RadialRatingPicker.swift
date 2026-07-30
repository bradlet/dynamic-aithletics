//
//  RadialRatingPicker.swift
//  Hybrid AIthletics
//
//  A Garmin-style radial dial for the two subjective workout ratings. Only
//  the top arc of a large circle is visible; the athlete swipes horizontally
//  to rotate slots through the 12 o'clock position. Generic over the slot
//  content so the feeling dial can show faces and the exertion dial numerals.
//
//  All geometry lives in `RadialDialGeometry` so it can be unit-tested.
//

import SwiftUI

/// A radial rating dial with a plain-English readout and chevron steppers.
///
/// Slot `0` is always "unset" and sits at the left end of the strip, which is
/// where the dial parks by default. The strip clamps at both ends with
/// rubber-band resistance rather than wrapping, so the athlete can never spin
/// from the top of the scale back through "unset" into the bottom of it.
///
/// State is owned by the parent view via `selection`.
struct RadialRatingPicker<ItemContent: View>: View {

    /// Selected value, or `nil` when the athlete has not rated the workout.
    @Binding var selection: Int?
    /// Values the dial offers, occupying slots `1...n`.
    let range: ClosedRange<Int>
    /// Angular pitch between adjacent slots. Wider scales want a tighter
    /// pitch so a useful span stays inside the visible band.
    let degreesPerItem: Double
    /// Plain-English name shown above the arc.
    let displayName: (Int?) -> String
    /// Accessibility label for the dial as a whole, e.g. "How did it feel".
    let accessibilityTitle: String
    /// Prefix for accessibility identifiers, e.g. `"feelingPicker"`.
    let identifier: String
    /// Builds the content for one slot, given its value and whether it is the
    /// slot currently at 12 o'clock.
    @ViewBuilder let itemContent: (Int?, Bool) -> ItemContent

    // MARK: - Dial metrics

    /// Radius of the underlying circle. Large relative to the visible band so
    /// the arc reads as a shallow curve rather than a wheel.
    private static var radius: CGFloat { 260 }
    /// Height of the visible band the arc is clipped to.
    private static var arcHeight: CGFloat { 104 }
    /// Distance from the band's top edge to the arc's apex.
    private static var topInset: CGFloat { 16 }
    /// Detents at which a slot has fully faded out.
    private static var visibleSpan: Double { 3.2 }

    // MARK: - State

    /// Continuous slot coordinate. Whatever sits here is at 12 o'clock.
    @State private var position: Double = 0
    /// Position when the current drag began.
    @State private var dragBase: Double = 0
    /// `nil` until a drag declares its direction; `false` means the enclosing
    /// scroll view owns it and the dial must stay put.
    @State private var isHorizontalDrag: Bool?

    /// Every slot on the dial, unset first.
    private var slots: [Int?] { [nil] + range.map { Optional($0) } }

    /// Slot currently nearest 12 o'clock. Derived from the *continuous*
    /// position so it updates mid-drag, which is what drives the detent
    /// haptics.
    private var liveIndex: Int {
        RadialDialGeometry.snappedIndex(position: position, itemCount: slots.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            valueLabel
            HStack(spacing: 4) {
                stepper(delta: -1, systemImage: "chevron.left", label: "Lower")
                dial
                stepper(delta: 1, systemImage: "chevron.right", label: "Raise")
            }
            clearButton
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: liveIndex)
        .onAppear { syncPositionToSelection(animated: false) }
        .onChange(of: selection) { _, _ in
            // Only follow external edits; a commit from this view has already
            // moved `position` to the matching slot.
            guard liveIndex != slotIndexForSelection else { return }
            syncPositionToSelection(animated: true)
        }
    }

    // MARK: - Readout

    private var valueLabel: some View {
        Text(displayName(selection))
            .font(.title3.weight(.semibold))
            .foregroundStyle(selection == nil ? Color.secondary : Color.primary)
            .animation(.easeOut(duration: 0.22), value: selection)
            .accessibilityIdentifier("\(identifier).valueLabel")
    }

    // MARK: - Dial

    private var dial: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(slots.indices, id: \.self) { index in
                    let offset = Double(index) - position
                    itemContent(slots[index], index == liveIndex)
                        .scaleEffect(RadialDialGeometry.scale(itemOffset: offset))
                        .opacity(
                            RadialDialGeometry.opacity(
                                itemOffset: offset,
                                visibleSpan: Self.visibleSpan
                            )
                        )
                        .position(
                            RadialDialGeometry.itemPoint(
                                itemOffset: offset,
                                degreesPerItem: degreesPerItem,
                                radius: Self.radius,
                                size: proxy.size,
                                topInset: Self.topInset
                            )
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: Self.arcHeight)
        .background(arcGuide)
        // `.position` places children in the parent's coordinate space with no
        // clipping of its own, so without this the far slots would draw over
        // neighbouring Form rows.
        .clipped()
        .mask(Self.edgeFade)
        .overlay(alignment: .top) { topCaret }
        .contentShape(Rectangle())
        .gesture(drag)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("\(identifier).dial")
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(displayName(selection))
        // `accessibilityAdjustableAction` is what makes the element adjustable
        // to VoiceOver; there is no matching trait to add.
        .accessibilityAdjustableAction { direction in
            step(by: direction == .increment ? 1 : -1)
        }
    }

    /// Faint arc the slots ride along, so the curve reads even when the
    /// neighbouring slots have faded out.
    private var arcGuide: some View {
        GeometryReader { proxy in
            Circle()
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                .frame(width: Self.radius * 2, height: Self.radius * 2)
                .position(
                    x: proxy.size.width / 2,
                    y: Self.topInset + Self.radius
                )
        }
        .allowsHitTesting(false)
    }

    /// Small marker at 12 o'clock showing where the selection lands.
    private var topCaret: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.45))
            .frame(width: 3, height: 8)
            .allowsHitTesting(false)
    }

    /// Horizontal fade so slots dissolve over the horizon instead of popping
    /// against a hard clip edge.
    private static var edgeFade: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.18),
                .init(color: .black, location: 0.82),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Steppers

    private func stepper(delta: Int, systemImage: String, label: String) -> some View {
        Button {
            step(by: delta)
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.secondary.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(identifier).\(delta > 0 ? "increment" : "decrement")")
        .accessibilityLabel("\(label) \(accessibilityTitle.lowercased())")
    }

    @ViewBuilder
    private var clearButton: some View {
        if selection != nil {
            Button {
                commit(0, animated: true)
            } label: {
                Label("Clear", systemImage: "xmark")
                    .labelStyle(.titleAndIcon)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .accessibilityIdentifier("\(identifier).clear")
            .accessibilityLabel("Clear \(accessibilityTitle.lowercased())")
        }
    }

    // MARK: - Gesture

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if isHorizontalDrag == nil {
                    // Declare direction once so a vertical swipe is left to
                    // the enclosing Form's scroll view.
                    let travel = abs(value.translation.width) + abs(value.translation.height)
                    guard travel > 8 else { return }
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                    dragBase = position
                }
                guard isHorizontalDrag == true else { return }
                position = RadialDialGeometry.position(
                    basePosition: dragBase,
                    translation: value.translation.width,
                    radius: Self.radius,
                    degreesPerItem: degreesPerItem,
                    itemCount: slots.count
                )
            }
            .onEnded { value in
                defer { isHorizontalDrag = nil }
                guard isHorizontalDrag == true else { return }
                // Let a flick carry the dial past where the finger lifted.
                let settled = RadialDialGeometry.position(
                    basePosition: dragBase,
                    translation: value.predictedEndTranslation.width,
                    radius: Self.radius,
                    degreesPerItem: degreesPerItem,
                    itemCount: slots.count
                )
                commit(
                    RadialDialGeometry.snappedIndex(position: settled, itemCount: slots.count),
                    animated: true
                )
            }
    }

    // MARK: - Actions

    /// Slot index matching the current binding value.
    private var slotIndexForSelection: Int {
        RadialDialGeometry.slotIndex(for: selection, lowerBound: range.lowerBound)
    }

    private func step(by delta: Int) {
        commit(
            RadialDialGeometry.stepped(index: liveIndex, by: delta, itemCount: slots.count),
            animated: true
        )
    }

    /// Parks the dial on `index` and publishes the matching value.
    private func commit(_ index: Int, animated: Bool) {
        let newValue = RadialDialGeometry.value(
            atSlotIndex: index,
            lowerBound: range.lowerBound,
            itemCount: slots.count
        )
        withAnimation(animated ? .snappy(duration: 0.28, extraBounce: 0.12) : nil) {
            position = Double(index)
            selection = newValue
        }
    }

    /// Re-parks the dial after the binding changes from outside this view —
    /// needed because hosting sheets seed their state in `init`.
    private func syncPositionToSelection(animated: Bool) {
        let index = slotIndexForSelection
        withAnimation(animated ? .snappy(duration: 0.28, extraBounce: 0.12) : nil) {
            position = Double(index)
        }
    }
}

// MARK: - Configured dials

/// The feeling dial: 1–5, with the scaling face glyphs riding the arc.
struct FeelingDial: View {
    @Binding var selection: Int?

    var body: some View {
        RadialRatingPicker(
            selection: $selection,
            range: FeelingVisuals.range,
            degreesPerItem: 17,
            displayName: FeelingVisuals.displayName,
            accessibilityTitle: "How did it feel",
            identifier: "feelingPicker"
        ) { value, isSelected in
            Image(systemName: FeelingVisuals.symbolName(for: value))
                .font(.system(size: isSelected ? 40 : 30, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(FeelingVisuals.tint(for: value))
        }
    }
}

/// The perceived-exertion dial: 1–10, with numerals riding the arc.
struct ExertionDial: View {
    @Binding var selection: Int?

    var body: some View {
        RadialRatingPicker(
            selection: $selection,
            range: ExertionVisuals.range,
            degreesPerItem: 13,
            displayName: ExertionVisuals.displayName,
            accessibilityTitle: "How hard was it",
            identifier: "exertionPicker"
        ) { value, isSelected in
            Text(value.map(String.init) ?? "—")
                .font(.system(size: isSelected ? 30 : 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ExertionVisuals.tint(for: value))
        }
    }
}

// MARK: - Preview

#Preview("Both dials in a Form") {
    struct Harness: View {
        @State private var feeling: Int?
        @State private var exertion: Int?
        var body: some View {
            Form {
                Section("How did it feel?") { FeelingDial(selection: $feeling) }
                Section("How hard was it?") { ExertionDial(selection: $exertion) }
                Section("Notes") {
                    TextField("How did it go?", text: .constant(""), axis: .vertical)
                }
            }
        }
    }
    return Harness()
}

#Preview("Dark — preselected") {
    struct Harness: View {
        @State private var feeling: Int? = 5
        @State private var exertion: Int? = 8
        var body: some View {
            Form {
                Section("How did it feel?") { FeelingDial(selection: $feeling) }
                Section("How hard was it?") { ExertionDial(selection: $exertion) }
            }
            .preferredColorScheme(.dark)
        }
    }
    return Harness()
}
