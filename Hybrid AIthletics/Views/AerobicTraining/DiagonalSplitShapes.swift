//
//  DiagonalSplitShapes.swift
//  Hybrid AIthletics
//
//  Shapes backing the completed/planned diagonal split on exercise cards.
//

import SwiftUI

/// Quadrilateral covering the left portion of a rect with a slanted right edge.
/// Fills the "completed" half of a split exercise card.
struct DiagonalSplitShape: Shape {
    /// Where the diagonal crosses horizontally, as a fraction of the rect's width.
    var midFraction: CGFloat = 0.62
    /// Horizontal offset of the diagonal's top endpoint (bottom is mirrored) in points.
    var slant: CGFloat = 6

    /// Builds the left-half quadrilateral path within `rect`.
    func path(in rect: CGRect) -> Path {
        let midX = rect.width * midFraction
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX + slant, y: rect.minY))
        path.addLine(to: CGPoint(x: midX - slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Just the diagonal divider line of `DiagonalSplitShape`, for stroking.
struct DiagonalDividerShape: Shape {
    /// Where the diagonal crosses horizontally, as a fraction of the rect's width.
    var midFraction: CGFloat = 0.62
    /// Horizontal offset of the diagonal's top endpoint (bottom is mirrored) in points.
    var slant: CGFloat = 6

    /// Builds the divider line path within `rect`.
    func path(in rect: CGRect) -> Path {
        let midX = rect.width * midFraction
        var path = Path()
        path.move(to: CGPoint(x: midX + slant, y: rect.minY))
        path.addLine(to: CGPoint(x: midX - slant, y: rect.maxY))
        return path
    }
}

#Preview("Split fills") {
    VStack(spacing: 12) {
        ForEach(
            [PlanPerformance.belowPlan, .atPlan, .abovePlan],
            id: \.self
        ) { performance in
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.1))
                DiagonalSplitShape().fill(performance.color.opacity(0.28))
                DiagonalDividerShape().stroke(performance.color.opacity(0.8), lineWidth: 1.5)
            }
            .frame(height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    .padding()
}
