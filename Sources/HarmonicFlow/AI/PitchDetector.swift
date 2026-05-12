import Foundation
import Accelerate

class PitchDetector {
    // A simple YIN-like algorithm implementation for fundamental frequency detection
    // adapted for a continuous audio buffer

    let sampleRate: Float = 44100.0
    let bufferSize = 2048

    func detectPitch(buffer: [Float]) -> Float? {
        guard buffer.count >= bufferSize else { return nil }

        let halfBufferSize = bufferSize / 2
        var difference = [Float](repeating: 0.0, count: halfBufferSize)

        // Step 1: Difference function
        for tau in 0..<halfBufferSize {
            for i in 0..<halfBufferSize {
                let delta = buffer[i] - buffer[i + tau]
                difference[tau] += delta * delta
            }
        }

        // Step 2: Cumulative mean normalized difference function
        var cumulativeMeanNormalizedDifference = [Float](repeating: 0.0, count: halfBufferSize)
        cumulativeMeanNormalizedDifference[0] = 1.0
        var runningSum: Float = 0.0
        for tau in 1..<halfBufferSize {
            runningSum += difference[tau]
            cumulativeMeanNormalizedDifference[tau] = difference[tau] * Float(tau) / runningSum
        }

        // Step 3: Absolute threshold
        let threshold: Float = 0.1
        var tauEstimate: Int = -1
        for tau in 2..<halfBufferSize {
            if cumulativeMeanNormalizedDifference[tau] < threshold {
                while tau + 1 < halfBufferSize && cumulativeMeanNormalizedDifference[tau + 1] < cumulativeMeanNormalizedDifference[tau] {
                    tauEstimate = tau + 1
                }
                tauEstimate = tau
                break
            }
        }

        if tauEstimate == -1 {
            // If no dip found below threshold, look for absolute minimum
            var minVal: Float = 1.0
            for tau in 2..<halfBufferSize {
                if cumulativeMeanNormalizedDifference[tau] < minVal {
                    minVal = cumulativeMeanNormalizedDifference[tau]
                    tauEstimate = tau
                }
            }
        }

        // Parabolic interpolation for better accuracy could go here

        if tauEstimate > 0 {
            let frequency = sampleRate / Float(tauEstimate)
            // Filter out unreasonable frequencies for human voice/melody
            if frequency > 80 && frequency < 1000 {
                return frequency
            }
        }

        return nil
    }

    func frequencyToMidi(_ frequency: Float) -> Int {
        let midi = 69.0 + 12.0 * log2(frequency / 440.0)
        return Int(round(midi))
    }
}
