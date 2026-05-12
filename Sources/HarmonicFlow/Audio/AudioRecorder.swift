import Foundation
import AVFoundation

class AudioRecorder: ObservableObject {
    private var engine: AVAudioEngine
    private let pitchDetector = PitchDetector()

    @Published var isRecording = false
    @Published var currentNotes: [Int] = []

    private var inputNode: AVAudioInputNode!
    private var sampleAccumulator: [Float] = []
    private let targetBufferSize = 2048

    init(engine: AVAudioEngine) {
        self.engine = engine
    }

    func setupRecording() {
        // Explicitly request microphone permissions to avoid crashing
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                print("Microphone permission denied.")
                return
            }

            DispatchQueue.main.async {
                self?.installTap()
            }
        }
    }

    private func installTap() {
        inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self, self.isRecording else { return }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            let floatArray = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            self.sampleAccumulator.append(contentsOf: floatArray)

            if self.sampleAccumulator.count >= self.targetBufferSize {
                let bufferToProcess = Array(self.sampleAccumulator.prefix(self.targetBufferSize))
                self.sampleAccumulator.removeFirst(self.targetBufferSize)

                if let frequency = self.pitchDetector.detectPitch(buffer: bufferToProcess) {
                    let midiNote = self.pitchDetector.frequencyToMidi(frequency)

                    DispatchQueue.main.async {
                        if self.currentNotes.last != midiNote {
                            self.currentNotes.append(midiNote)
                        }
                    }
                }
            }
        }
    }

    func startRecording() {
        currentNotes.removeAll()
        sampleAccumulator.removeAll()
        isRecording = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            if self?.isRecording == true {
                self?.stopRecording()
            }
        }
    }

    func stopRecording() {
        isRecording = false
    }
}
