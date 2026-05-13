import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioEngineManager()

    @State private var selectedRootIndex = 0
    @State private var selectedQualityIndex = 0

    // Track active interactions
    @State private var isRootInteracting = false
    @State private var isQualityInteracting = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Top Bar
                HStack {
                    Text("HarmonicFlow")
                        .font(.largeTitle.weight(.black))
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("Arp", isOn: $audioManager.isArpRunning)
                        .toggleStyle(.button)
                        .tint(.cyan)

                    Toggle("Legato", isOn: $audioManager.isLegatoEnabled)
                        .toggleStyle(.button)
                        .tint(.green)
                }
                .padding()

                Spacer()

                // Main Performance Area
                HStack {
                    // Left Control (Root Note)
                    RadialDialView(
                        segments: rootNotes,
                        selectedIndex: $selectedRootIndex,
                        title: "Root",
                        onChange: {
                            audioManager.sendCC(cc: 20, value: UInt8(selectedRootIndex * 10))
                            updatePlayback()
                        },
                        onInteractionChange: { isInteracting in
                            isRootInteracting = isInteracting
                            updatePlayback()
                        }
                    )
                    .frame(width: 320, height: 320)
                    .padding(.leading, 30)

                    Spacer()

                    // Center Active Chord Display
                    VStack {
                        Text("Active Chord")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(currentChordName)
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(isCurrentlyPlaying ? .cyan : .white)
                            .shadow(color: isCurrentlyPlaying ? .cyan.opacity(0.8) : .clear, radius: 20, x: 0, y: 0)
                    }

                    Spacer()

                    // Right Control (Quality)
                    RadialDialView(
                        segments: chordQualities,
                        selectedIndex: $selectedQualityIndex,
                        title: "Quality",
                        onChange: {
                            audioManager.sendCC(cc: 21, value: UInt8(selectedQualityIndex * 15))
                            updatePlayback()
                        },
                        onInteractionChange: { isInteracting in
                            isQualityInteracting = isInteracting
                            updatePlayback()
                        }
                    )
                    .frame(width: 320, height: 320)
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 20)

                Spacer()
            }
        }
        .onAppear {
            // No auto-play on appear, must be touched
        }
    }

    var currentChordName: String {
        return "\(rootNotes[selectedRootIndex])\(chordQualities[selectedQualityIndex])"
    }

    var isCurrentlyPlaying: Bool {
        return isRootInteracting || isQualityInteracting
    }

    func updatePlayback() {
        if isCurrentlyPlaying {
            playCurrentChord()
        } else {
            audioManager.stopAll()
        }
    }

    func playCurrentChord() {
        let notes = generateChordNotes(rootIndex: selectedRootIndex, qualityIndex: selectedQualityIndex)
        audioManager.playChord(notes: notes)
    }

    func generateChordNotes(rootIndex: Int, qualityIndex: Int) -> [Int] {
        let rootMidi = 60 + rootIndex // C4 is 60
        var intervals: [Int] = [0]

        switch chordQualities[qualityIndex] {
        case "maj": intervals = [0, 4, 7]
        case "maj7": intervals = [0, 4, 7, 11]
        case "7": intervals = [0, 4, 7, 10]
        case "sus4": intervals = [0, 5, 7]
        case "m": intervals = [0, 3, 7]
        case "m7": intervals = [0, 3, 7, 10]
        case "dim": intervals = [0, 3, 6]
        case "aug": intervals = [0, 4, 8]
        default: break
        }

        return intervals.map { rootMidi + $0 }
    }
}
