import Foundation
import AVFoundation

class AudioEngineManager: ObservableObject {
    let engine = AVAudioEngine()
    let synth = WavetableSynth()
    var synthNode: AVAudioSourceNode!

    let arpeggiator = Arpeggiator()
    let midiManager = MIDIManager()

    @Published var isArpRunning: Bool = false {
        didSet {
            if isArpRunning {
                synth.allNotesOff()
                arpeggiator.start()
            } else {
                arpeggiator.stop()
                synth.allNotesOff()
            }
        }
    }

    @Published var isLegatoEnabled: Bool = false {
        didSet {
            arpeggiator.isLegatoEnabled = isLegatoEnabled
        }
    }

    private var currentlyPlayingNotes: Set<Int> = []

    init() {
        setupSynthNode()
        setupAudioSession()
        setupEngine()
        setupArpeggiator()
    }

    private func setupSynthNode() {
        synthNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            self.synth.render(frameCount: frameCount, ablPointer: ablPointer)
            return noErr
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            let preferredBufferSize = 64.0 / session.sampleRate
            try session.setPreferredIOBufferDuration(preferredBufferSize)
            try session.setActive(true)
            synth.setSampleRate(Float(session.sampleRate))
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func setupEngine() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.attach(synthNode)
        engine.connect(synthNode, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func setupArpeggiator() {
        arpeggiator.onNoteTrigger = { [weak self] note in
            self?.triggerNoteOn(note: note)
        }
        arpeggiator.onNoteOff = { [weak self] note in
            self?.triggerNoteOff(note: note)
        }
    }

    // MARK: - Synth & MIDI Control

    func playChord(notes: [Int]) {
        if isArpRunning {
            arpeggiator.updateNotes(notes)
        } else {
            // Turn off existing notes not in new chord
            for note in currentlyPlayingNotes {
                if !notes.contains(note) {
                    triggerNoteOff(note: note)
                }
            }
            // Turn on new notes
            for note in notes {
                if !currentlyPlayingNotes.contains(note) {
                    triggerNoteOn(note: note)
                }
            }
        }
    }

    func stopAll() {
        for note in currentlyPlayingNotes {
            triggerNoteOff(note: note)
        }
        arpeggiator.stop()
    }

    private func triggerNoteOn(note: Int) {
        synth.noteOn(note: note, velocity: 0.8)
        midiManager.sendNoteOn(note: note, velocity: 100)
        currentlyPlayingNotes.insert(note)
    }

    private func triggerNoteOff(note: Int) {
        synth.noteOff(note: note)
        midiManager.sendNoteOff(note: note)
        currentlyPlayingNotes.remove(note)
    }

    func sendCC(cc: UInt8, value: UInt8) {
        midiManager.sendControlChange(cc: cc, value: value)
    }
}
