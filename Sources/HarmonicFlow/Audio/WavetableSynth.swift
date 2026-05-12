import Foundation
import AVFoundation

enum WaveformType {
    case sine, saw, square, neoSoulEP
}

class Voice {
    var frequency: Float = 440.0
    var phase: Float = 0.0
    var phaseIncrement: Float = 0.0
    var amplitude: Float = 0.0
    var isActive: Bool = false
    var noteNumber: Int = 60

    // Envelope
    var envAttack: Float = 0.01
    var envDecay: Float = 0.1
    var envSustain: Float = 0.8
    var envRelease: Float = 0.5
    var envState: EnvState = .idle
    var envLevel: Float = 0.0

    enum EnvState { case idle, attack, decay, sustain, release }

    func start(frequency: Float, sampleRate: Float) {
        self.frequency = frequency
        self.phaseIncrement = frequency * 2.0 * .pi / sampleRate
        self.envState = .attack
        self.isActive = true
    }

    func stop() {
        self.envState = .release
    }

    func process(waveform: WaveformType) -> Float {
        guard isActive else { return 0.0 }

        var sample: Float = 0.0

        switch waveform {
        case .sine:
            sample = sin(phase)
        case .saw:
            sample = 2.0 * (phase / (2.0 * .pi)) - 1.0
            if sample > 1.0 { sample -= 2.0 }
        case .square:
            sample = phase < .pi ? 1.0 : -1.0
        case .neoSoulEP:
            // FM Approximation
            let fmPhase = phase * 2.0 // Modulator frequency ratio
            let mod = sin(fmPhase) * 2.5 // Modulation index
            sample = sin(phase + mod) * 0.8
            // Add some warmth (even harmonics)
            sample += sin(phase * 2) * 0.2
        }

        phase += phaseIncrement
        if phase >= 2.0 * .pi {
            phase -= 2.0 * .pi
        }

        // Very basic envelope generator tick
        // (In a real app, this would use delta time)
        let sampleRate: Float = 44100.0 // Hardcoded for this simple example

        switch envState {
        case .idle:
            envLevel = 0.0
            isActive = false
        case .attack:
            envLevel += 1.0 / (envAttack * sampleRate)
            if envLevel >= 1.0 {
                envLevel = 1.0
                envState = .decay
            }
        case .decay:
            envLevel -= (1.0 - envSustain) / (envDecay * sampleRate)
            if envLevel <= envSustain {
                envLevel = envSustain
                envState = .sustain
            }
        case .sustain:
            envLevel = envSustain
        case .release:
            envLevel -= envSustain / (envRelease * sampleRate)
            if envLevel <= 0.0 {
                envLevel = 0.0
                envState = .idle
                isActive = false
            }
        }

        return sample * envLevel
    }
}

class WavetableSynth {
    let maxVoices = 16
    var voices: [Voice] = []
    var waveform: WaveformType = .neoSoulEP
    var sampleRate: Float = 44100.0

    init() {
        for _ in 0..<maxVoices {
            voices.append(Voice())
        }
    }

    func setSampleRate(_ rate: Float) {
        self.sampleRate = rate
    }

    func noteOn(note: Int, velocity: Float) {
        // Find free voice
        if let voice = voices.first(where: { !$0.isActive }) {
            let freq = 440.0 * pow(2.0, Float(note - 69) / 12.0)
            voice.noteNumber = note
            voice.amplitude = velocity
            voice.start(frequency: freq, sampleRate: sampleRate)
        }
    }

    func noteOff(note: Int) {
        for voice in voices where voice.noteNumber == note && voice.isActive {
            voice.stop()
        }
    }

    func allNotesOff() {
        for voice in voices {
            voice.stop()
        }
    }

    func render(frameCount: AVAudioFrameCount, ablPointer: UnsafeMutableAudioBufferListPointer) {
        for frame in 0..<Int(frameCount) {
            var mix: Float = 0.0
            for voice in voices {
                mix += voice.process(waveform: waveform)
            }
            // Simple limiting to prevent clipping
            if mix > 1.0 { mix = 1.0 }
            if mix < -1.0 { mix = -1.0 }

            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = mix * 0.2 // Master volume attenuation
            }
        }
    }
}
