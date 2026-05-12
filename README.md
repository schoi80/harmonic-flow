# HarmonicFlow

HarmonicFlow is a multi-touch copilot synthesizer for iOS 17+. It acts as an advanced musical instrument featuring real-time melodic transcription, a polyphonic wavetable synthesizer, multi-touch dual-dial chord controls, and a local AI "Music Theory Copilot" to suggest chord progressions based on your vocal or melodic inputs.

## Features

- **Dual-Dial Multi-Touch Interface**: Swipe around the intuitive Root and Quality dials to seamlessly trigger complex chords on the fly.
- **Polyphonic Wavetable Synth**: Built-in, low-latency synthesis with a Neo-Soul Electric Piano patch and basic waveforms.
- **Arpeggiator with Legato Mode**: Instantly arpeggiates the active chord with seamless transitions using custom note-off overlap.
- **Wireless MIDI**: Broadcaster capabilities using Network RTP MIDI, allowing HarmonicFlow to send Note On/Off and CC data to any DAW (Logic Pro, Ableton, etc.) wirelessly.
- **Music Theory Copilot**: Records your melody via the microphone, detects the pitch, converts it to MIDI, and uses a local quantized Gemma 2b/4b LLM (via LiteRT) to suggest chord progressions tailored to different genres (e.g., Neo-Soul, Jazz, K-Pop).

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation & Setup

1. **Clone the repository**:
   \`\`\`bash
   git clone https://github.com/your-username/HarmonicFlow.git
   cd HarmonicFlow
   \`\`\`

2. **Generate Xcode Project (Optional)**:
   If you have XcodeGen installed, you can generate the `.xcodeproj` file:
   \`\`\`bash
   xcodegen generate
   \`\`\`
   Alternatively, you can open the folder directly in Xcode using the `Package.swift`.

3. **Open the Project**:
   Open `HarmonicFlow.xcodeproj` (or open the package folder) in Xcode.

4. **Build and Run**:
   Select your desired simulator or a physical iOS 17+ device and hit **Run** (Cmd + R).
   *Note: Real-time audio pitch detection and LiteRT inference run significantly better on a physical device.*

## How to Use

1. **Multi-Touch Dials**:
   - The left dial controls the **Root Note** (C, C#, D, etc.).
   - The right dial controls the **Chord Quality** (maj, min, maj7, etc.).
   - Slide your fingers around to instantly change the underlying active chord.

2. **Arpeggiator & Legato**:
   - Toggle "Arp" at the top to engage the arpeggiator. It automatically snaps to your newly selected chords.
   - Toggle "Legato" to overlap Note-On/Note-Off events for gapless melodic transitions.

3. **AI Copilot**:
   - Select a genre (e.g., Neo-Soul).
   - Press **Record Melody** and sing or play an instrument into the microphone.
   - Press **Stop & Analyze** to stop recording. The app translates the pitch buffer into a sequence of MIDI notes and passes it to the local LLM to generate a corresponding chord progression suggestion.

4. **MIDI Out**:
   - Connect your iPhone to your Mac's Audio MIDI Setup via Wi-Fi Network MIDI (RTP).
   - HarmonicFlow will broadcast Note events and dial movements as CC data (CC20 and CC21).

## Important Note on AI Inference (LiteRT/TensorFlow)

This repository currently uses a compiled **stub** module (`Sources/TensorFlowLite`) to allow the project to build cleanly out-of-the-box via Swift Package Manager (which official TensorFlow does not natively support well).

**Before deploying to TestFlight or the App Store, you must swap this stub with the real XCFramework.**

To do this:
1. Delete `Sources/TensorFlowLite`.
2. Install via CocoaPods (`pod "TensorFlowLiteSwift"`) or link a downloaded `.xcframework` binary in Xcode.

## Architecture

- **`AudioEngineManager`**: Handles `AVAudioEngine`, audio sessions (low-latency 64-sample buffer), and acts as the orchestrator.
- **`WavetableSynth` & `Arpeggiator`**: The core sound generation engines.
- **`PitchDetector`**: A custom YIN-like fundamental frequency detection algorithm to convert incoming audio to MIDI.
- **`LiteRTManager`**: Manages the local TensorFlow Lite (LiteRT) inference, processing prompts for the Gemma model.
- **`MIDIManager`**: Uses CoreMIDI to broadcast virtual endpoint data over the network.
- **SwiftUI Views**: Custom-drawn radial ZStack layouts for touch inputs and haptics.

## License

MIT License. See `LICENSE` for details.
