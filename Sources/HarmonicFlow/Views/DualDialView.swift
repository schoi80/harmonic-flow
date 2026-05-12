import SwiftUI

// Represents the 12 musical roots
let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

// Represents common chord qualities
let chordQualities = ["maj", "maj7", "7", "sus4", "m", "m7", "dim", "aug"]

struct DualDialView: View {
    @Binding var selectedRootIndex: Int
    @Binding var selectedQualityIndex: Int
    var onChordChange: () -> Void
    var onRootCC: ((UInt8) -> Void)?
    var onQualityCC: ((UInt8) -> Void)?

    var body: some View {
        HStack(spacing: 50) {
            // Left Control (Root Note)
            RadialDialView(
                segments: rootNotes,
                selectedIndex: $selectedRootIndex,
                title: "Root",
                onChange: {
                    onChordChange()
                    onRootCC?(UInt8(selectedRootIndex * 10)) // map 0-11 to 0-110 CC val
                }
            )
            .frame(width: 250, height: 250)

            // Right Control (Quality)
            RadialDialView(
                segments: chordQualities,
                selectedIndex: $selectedQualityIndex,
                title: "Quality",
                onChange: {
                    onChordChange()
                    onQualityCC?(UInt8(selectedQualityIndex * 15)) // map 0-7 to 0-105 CC val
                }
            )
            .frame(width: 250, height: 250)
        }
    }
}

struct RadialDialView: View {
    let segments: [String]
    @Binding var selectedIndex: Int
    let title: String
    var onChange: () -> Void

    @State private var dragAngle: Angle = .zero

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = geometry.size.width / 2

            ZStack {
                // Background
                Circle()
                    .fill(Color(white: 0.15))
                    .shadow(radius: 10)

                // Segments
                ForEach(0..<segments.count, id: \.self) { index in
                    let angle = Angle(degrees: Double(index) / Double(segments.count) * 360.0 - 90.0)

                    Text(segments[index])
                        .font(.system(size: 16, weight: selectedIndex == index ? .bold : .regular))
                        .foregroundColor(selectedIndex == index ? .cyan : .gray)
                        .position(
                            x: center.x + CGFloat(cos(angle.radians)) * (radius - 30),
                            y: center.y + CGFloat(sin(angle.radians)) * (radius - 30)
                        )
                }

                // Center Label
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 80, height: 80)

                VStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(segments[selectedIndex])
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                // Selection Indicator Arc
                let segmentAngle = 360.0 / Double(segments.count)
                let startAngle = Angle(degrees: Double(selectedIndex) * segmentAngle - 90.0 - segmentAngle/2)
                let endAngle = Angle(degrees: Double(selectedIndex) * segmentAngle - 90.0 + segmentAngle/2)

                Path { path in
                    path.addArc(center: center, radius: radius - 5, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }
                .stroke(Color.cyan, lineWidth: 10)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
                        var angle = atan2(vector.dy, vector.dx) + .pi / 2 // Offset by 90deg so top is 0
                        if angle < 0 { angle += 2 * .pi }

                        let degrees = angle * 180 / .pi
                        let segmentSize = 360.0 / Double(segments.count)

                        // Calculate index and round to nearest segment
                        var newIndex = Int(round(degrees / segmentSize)) % segments.count
                        if newIndex < 0 { newIndex += segments.count }

                        if newIndex != selectedIndex {
                            selectedIndex = newIndex
                            triggerHaptic()
                            onChange()
                        }
                    }
            )
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
