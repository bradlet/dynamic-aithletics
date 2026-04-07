//
//  FeltRatingPicker.swift
//  Hybrid AIthletics
//
//  A distinctive "How did it feel?" picker that captures a subjective effort
//  rating from 1 (brutal) to 10 (amazing). Stores 0 when the user skips.
//  Feeds the on-device AI Coach's training-load assessment.
//

import SwiftUI

/// A tactile 1–10 effort rating control with a morphing face indicator.
///
/// The picker renders a large face symbol whose expression and tint shift
/// along a red → amber → green ramp to match the selected effort level,
/// paired with a row of ten tappable capsule dots. A value of `0` represents
/// "not set" and shows a neutral placeholder. Emits selection haptics and
/// uses spring animations for a tactile feel inside the record-workout form.
struct FeltRatingPicker: View {
    /// Current rating. `0` means unset; `1...10` is the effort scale.
    @Binding var value: Int

    /// Descriptor words, indexed by value (0 = unset).
    private static let descriptors: [String] = [
        "Not set",
        "Brutal", "Rough", "Hard", "Tough", "Honest",
        "Steady", "Good", "Strong", "Great", "Amazing"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            scale
            footer
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How did it feel")
        .accessibilityValue(
            value == 0
                ? "Not set"
                : "\(value) of 10, \(Self.descriptors[value])"
        )
    }

    // MARK: - Header: morphing face + descriptor

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                currentTint.opacity(0.32),
                                currentTint.opacity(0.04)
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 44
                        )
                    )
                    .frame(width: 76, height: 76)

                Image(systemName: faceSymbol)
                    .font(.system(size: 46, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(currentTint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: value)

            VStack(alignment: .leading, spacing: 2) {
                Text(descriptor)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .id(descriptor)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        )
                    )

                Text(value == 0 ? "Tap a dot to rate your effort" : "\(value) of 10")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .animation(.easeOut(duration: 0.22), value: value)

            Spacer(minLength: 0)
        }
        .accessibilityHidden(true) // redundant with parent accessibilityValue
    }

    // MARK: - Scale: ten capsule dots

    private var scale: some View {
        HStack(spacing: 6) {
            ForEach(1...10, id: \.self) { index in
                dot(for: index)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dot(for index: Int) -> some View {
        let isSelected = index == value
        let isActive = value != 0 && index <= value
        let tint = tint(for: index)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                value = index
            }
        } label: {
            Capsule()
                .fill(isActive ? tint : Color.secondary.opacity(0.18))
                .frame(
                    width: isSelected ? 22 : 14,
                    height: isSelected ? 32 : 14
                )
                .overlay(
                    Capsule()
                        .strokeBorder(tint, lineWidth: 2)
                        .scaleEffect(1.4)
                        .opacity(isSelected ? 0.35 : 0)
                )
                .contentShape(Rectangle().inset(by: -6)) // generous hit target
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Effort \(index) of 10, \(Self.descriptors[index])")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Footer: clear button

    @ViewBuilder
    private var footer: some View {
        HStack {
            Spacer()
            if value != 0 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        value = 0
                    }
                } label: {
                    Label("Clear", systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.secondary.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel("Clear rating")
            }
        }
    }

    // MARK: - Derived visuals

    private var descriptor: String {
        Self.descriptors[max(0, min(10, value))]
    }

    /// Face symbol morphs across three expression tiers, plus unset.
    private var faceSymbol: String {
        switch value {
        case 0:      return "face.dashed"
        case 1...4:  return "face.dashed"           // struggle (red tint carries meaning)
        case 5...7:  return "face.smiling"          // steady
        case 8...10: return "face.smiling.inverse"  // triumph
        default:     return "face.dashed"
        }
    }

    private var currentTint: Color {
        value == 0 ? .secondary : tint(for: value)
    }

    /// Red → amber → green ramp for index 1...10, via HSB interpolation.
    private func tint(for index: Int) -> Color {
        let clamped = Double(max(1, min(10, index)) - 1) / 9.0  // 0...1
        let hue: Double = 0.0 + (0.37 * clamped)                // ~red → ~green
        return Color(hue: hue, saturation: 0.78, brightness: 0.92)
    }
}

// MARK: - Preview

#Preview("In Form") {
    struct Harness: View {
        @State private var value: Int = 0
        var body: some View {
            Form {
                Section("How did it feel?") {
                    FeltRatingPicker(value: $value)
                }
                Section("Notes") {
                    TextField("How did it go?", text: .constant(""), axis: .vertical)
                }
            }
        }
    }
    return Harness()
}

#Preview("Dark — Selected 9") {
    struct Harness: View {
        @State private var value: Int = 9
        var body: some View {
            Form {
                Section("How did it feel?") {
                    FeltRatingPicker(value: $value)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    return Harness()
}
