import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioEngineManager()
    @StateObject private var recorder: AudioRecorder

    @State private var selectedRootIndex = 0
    @State private var selectedQualityIndex = 0

    init() {
        let manager = AudioEngineManager()
        _audioManager = StateObject(wrappedValue: manager)
        _recorder = StateObject(wrappedValue: AudioRecorder(engine: manager.engine))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
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

                AICopilotView(recorder: recorder)

                Spacer()

                DualDialView(
                    selectedRootIndex: $selectedRootIndex,
                    selectedQualityIndex: $selectedQualityIndex,
                    onChordChange: playCurrentChord,
                    onRootCC: { val in audioManager.sendCC(cc: 20, value: val) },
                    onQualityCC: { val in audioManager.sendCC(cc: 21, value: val) }
                )

                Spacer()

                Text("Active Chord: \(currentChordName)")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            recorder.setupRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                playCurrentChord()
            }
        }
    }

    var currentChordName: String {
        return "\(rootNotes[selectedRootIndex])\(chordQualities[selectedQualityIndex])"
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
