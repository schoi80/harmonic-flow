import SwiftUI

struct AICopilotView: View {
    @ObservedObject var recorder: AudioRecorder
    @StateObject private var aiManager = LiteRTManager()

    @State private var genre = "Neo-Soul"
    @State private var suggestedChords: String = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Music Theory Copilot")
                .font(.headline)
                .foregroundColor(.cyan)

            if !aiManager.isModelLoaded {
                VStack {
                    Text("Loading LLM Engine...")
                    ProgressView(value: aiManager.downloadProgress)
                        .progressViewStyle(.linear)
                        .padding()
                }
                .onAppear {
                    aiManager.downloadAndLoadModel()
                }
            } else {
                HStack {
                    Text("Genre:")
                    Picker("Genre", selection: $genre) {
                        Text("Neo-Soul").tag("Neo-Soul")
                        Text("K-Pop").tag("K-Pop")
                        Text("Jazz").tag("Jazz")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                Button(action: {
                    if recorder.isRecording {
                        recorder.stopRecording()
                        processMelody()
                    } else {
                        suggestedChords = ""
                        recorder.startRecording()
                    }
                }) {
                    Text(recorder.isRecording ? "Stop & Analyze" : "Record Melody")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recorder.isRecording ? Color.red : Color.cyan)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if !recorder.currentNotes.isEmpty {
                    Text("Detected Notes: \(recorder.currentNotes.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if isProcessing {
                    ProgressView("Analyzing with Gemma...")
                        .padding()
                }

                if !suggestedChords.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggested Progression:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(suggestedChords)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(white: 0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(15)
        .padding()
    }

    func processMelody() {
        guard !recorder.currentNotes.isEmpty else { return }
        isProcessing = true

        aiManager.generateChordProgression(melodyMidi: recorder.currentNotes, key: "C", genre: genre) { chords in
            self.suggestedChords = chords
            self.isProcessing = false
        }
    }
}
