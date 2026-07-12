//
//  DurationWheelPickers.swift
//  Hybrid AIthletics
//
//  Shared hours/minutes/seconds wheel-picker row used by every duration
//  editor (workout forms, exercise scheduling, planned targets).
//

import SwiftUI

/// A horizontal row of three wheel pickers for entering a duration as
/// hours (0–23), minutes (0–59), and seconds (0–59). State is owned by
/// the parent view via bindings.
struct DurationWheelPickers: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack {
            Picker("Hours", selection: $hours) {
                ForEach(0..<24) { Text("\($0)h").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            Picker("Minutes", selection: $minutes) {
                ForEach(0..<60) { Text("\($0)m").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            Picker("Seconds", selection: $seconds) {
                ForEach(0..<60) { Text("\($0)s").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 120)
    }
}

#Preview {
    Form {
        Section("Duration") {
            DurationWheelPickers(
                hours: .constant(0),
                minutes: .constant(30),
                seconds: .constant(0)
            )
        }
    }
}
