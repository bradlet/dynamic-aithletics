//
//  RadialDialGeometry.swift
//  Hybrid AIthletics
//
//  Pure geometry and index math for `RadialRatingPicker`. Extracted so the
//  dial's drag → position → snapped-value behaviour can be unit-tested
//  without spinning up SwiftUI (same pattern as `WorkoutListPagination`).
//

import CoreGraphics
import Foundation

/// Stateless math for the radial rating dial.
///
/// The dial is a linear strip of slots bent onto the top arc of a large
/// circle whose centre sits below the visible band — not a closed ring.
/// Slot `0` is always the "unset" slot at the left end; slots `1...n` carry
/// the rating values. `position` is a continuous slot coordinate: whatever
/// sits at `position` is at 12 o'clock. Angles are degrees clockwise from
/// 12 o'clock, so a positive angle is right of centre.
enum RadialDialGeometry {

    /// Arc length in points spanned by one detent. Dragging the dial by this
    /// many points advances exactly one slot, so the strip tracks the finger
    /// 1:1 along the arc.
    /// - Parameters:
    ///   - radius: Radius of the underlying circle, in points.
    ///   - degreesPerItem: Angular pitch between adjacent slots.
    static func pointsPerItem(radius: CGFloat, degreesPerItem: Double) -> CGFloat {
        radius * CGFloat(degreesPerItem * .pi / 180)
    }

    /// Continuous position produced by an in-flight drag.
    ///
    /// Swiping left (negative `translation`) moves the strip left, bringing
    /// higher slots to the top, so `position` increases. Overscroll past
    /// either end is compressed by `resistance` so the dial feels bounded
    /// without hard-stopping under the finger; inside the bounds the result
    /// is exact.
    /// - Parameters:
    ///   - basePosition: Position when the drag began.
    ///   - translation: Horizontal drag translation in points.
    ///   - radius: Radius of the underlying circle, in points.
    ///   - degreesPerItem: Angular pitch between adjacent slots.
    ///   - itemCount: Total number of slots, including the unset slot.
    ///   - resistance: Overscroll compression factor. Smaller resists more.
    /// - Returns: A continuous slot coordinate. Returns `0` for a non-positive
    ///   `itemCount` and `basePosition` for a degenerate (zero-length) pitch.
    static func position(
        basePosition: Double,
        translation: CGFloat,
        radius: CGFloat,
        degreesPerItem: Double,
        itemCount: Int,
        resistance: Double = 0.35
    ) -> Double {
        guard itemCount > 0 else { return 0 }
        let perItem = Double(pointsPerItem(radius: radius, degreesPerItem: degreesPerItem))
        guard perItem > 0 else { return basePosition }

        let raw = basePosition - Double(translation) / perItem
        let upper = Double(itemCount - 1)
        if raw < 0 {
            return -pow(-raw, 0.75) * resistance
        } else if raw > upper {
            return upper + pow(raw - upper, 0.75) * resistance
        }
        return raw
    }

    /// Nearest valid slot index for a continuous position, clamped in range.
    /// - Parameters:
    ///   - position: Continuous slot coordinate.
    ///   - itemCount: Total number of slots.
    /// - Returns: A slot index in `0..<itemCount`, or `0` when `itemCount` is
    ///   non-positive.
    static func snappedIndex(position: Double, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return min(max(Int(position.rounded()), 0), itemCount - 1)
    }

    /// Signed angle in degrees (clockwise from 12 o'clock) for a slot sitting
    /// `itemOffset` detents away from the current position.
    /// - Parameters:
    ///   - itemOffset: Detents from the selection. Positive is to the right.
    ///   - degreesPerItem: Angular pitch between adjacent slots.
    static func angleDegrees(itemOffset: Double, degreesPerItem: Double) -> Double {
        itemOffset * degreesPerItem
    }

    /// Centre point of a slot inside a band of `size`.
    ///
    /// The circle's topmost point sits at `topInset` from the band's top edge,
    /// so its centre is at `(size.width / 2, topInset + radius)`.
    /// - Parameters:
    ///   - itemOffset: Detents from the selection. Positive is to the right.
    ///   - degreesPerItem: Angular pitch between adjacent slots.
    ///   - radius: Radius of the underlying circle, in points.
    ///   - size: Size of the visible band.
    ///   - topInset: Distance from the band's top edge to the arc's apex.
    static func itemPoint(
        itemOffset: Double,
        degreesPerItem: Double,
        radius: CGFloat,
        size: CGSize,
        topInset: CGFloat
    ) -> CGPoint {
        let theta = angleDegrees(itemOffset: itemOffset, degreesPerItem: degreesPerItem) * .pi / 180
        let centerX = size.width / 2
        let centerY = topInset + radius
        return CGPoint(
            x: centerX + radius * CGFloat(sin(theta)),
            y: centerY - radius * CGFloat(cos(theta))
        )
    }

    /// Render scale for a slot: `1.0` at the selection, tapering with
    /// distance. Floors at `floor` so distant slots stay legible right up to
    /// the point they fade out.
    /// - Parameters:
    ///   - itemOffset: Detents from the selection.
    ///   - floor: Smallest scale a slot may shrink to.
    static func scale(itemOffset: Double, floor: Double = 0.62) -> Double {
        max(floor, 1.0 - 0.16 * abs(itemOffset))
    }

    /// Render opacity for a slot: `1.0` at the selection, fading linearly to
    /// `0` at `visibleSpan` detents so slots disappear over the horizon.
    /// - Parameters:
    ///   - itemOffset: Detents from the selection.
    ///   - visibleSpan: Detents at which a slot becomes fully transparent.
    /// - Returns: An opacity in `0...1`. Returns `1` for a non-positive span.
    static func opacity(itemOffset: Double, visibleSpan: Double) -> Double {
        guard visibleSpan > 0 else { return 1 }
        return max(0, 1.0 - abs(itemOffset) / visibleSpan)
    }

    // MARK: - Slot ↔ value mapping

    /// Slot index holding a value. `nil` maps to slot `0`, the unset slot.
    /// - Parameters:
    ///   - value: The rating value, or `nil` for unset.
    ///   - lowerBound: Lowest value on the dial's scale (slot `1`).
    static func slotIndex(for value: Int?, lowerBound: Int) -> Int {
        guard let value else { return 0 }
        return max(0, value - lowerBound + 1)
    }

    /// Value held by a slot index. Slot `0` is the unset slot.
    /// - Parameters:
    ///   - index: Slot index.
    ///   - lowerBound: Lowest value on the dial's scale (slot `1`).
    ///   - itemCount: Total number of slots.
    /// - Returns: The rating value, or `nil` for slot `0` and out-of-range
    ///   indices.
    static func value(atSlotIndex index: Int, lowerBound: Int, itemCount: Int) -> Int? {
        guard index > 0, index < itemCount else { return nil }
        return lowerBound + index - 1
    }

    /// One stepper or accessibility increment, clamped in range.
    /// - Parameters:
    ///   - index: Current slot index.
    ///   - delta: Detents to move. Positive moves toward higher values.
    ///   - itemCount: Total number of slots.
    static func stepped(index: Int, by delta: Int, itemCount: Int) -> Int {
        min(max(index + delta, 0), max(0, itemCount - 1))
    }
}
