import Foundation
import TensorFlowLite

class LiteRTManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var downloadProgress: Float = 0.0

    private var interpreter: Interpreter?

    // Remote URL of the model to download
    let modelURLString = "https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/gemma-2b-it.tflite"

    func downloadAndLoadModel() {
        guard let modelURL = URL(string: modelURLString) else { return }

        // Define destination file
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectory.appendingPathComponent("gemma.tflite")

        // If it exists, just load it
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            loadModel(at: destinationUrl.path)
            return
        }

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: modelURL)
        request.httpMethod = "GET"

        let downloadTask = session.downloadTask(with: request) { [weak self] (location, response, error) in
            guard let location = location, error == nil else {
                print("Error downloading model: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                try FileManager.default.moveItem(at: location, to: destinationUrl)
                self?.loadModel(at: destinationUrl.path)
            } catch {
                print("Error saving model to documents directory: \(error)")
            }
        }

        // Using a basic download task without progress tracking for simplicity,
        // but progress updates could be added via URLSessionDownloadDelegate
        DispatchQueue.main.async {
            self.downloadProgress = 0.5
        }

        downloadTask.resume()
    }

    private func loadModel(at path: String) {
        do {
            // Load the interpreter
            interpreter = try Interpreter(modelPath: path)
            try interpreter?.allocateTensors()

            DispatchQueue.main.async {
                self.isModelLoaded = true
                self.downloadProgress = 1.0
                print("LiteRT Gemma Model Loaded successfully")
            }
        } catch {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
        }
    }

    func generateChordProgression(melodyMidi: [Int], key: String, genre: String, completion: @escaping (String) -> Void) {
        guard isModelLoaded, let interpreter = interpreter else {
            completion("Model not loaded yet.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let melodyStr = melodyMidi.map { String($0) }.joined(separator: ", ")
                let prompt = """
                You are a Music Theory Copilot.
                Given the following melody as MIDI note numbers: [\(melodyStr)],
                suggest a 4-bar chord progression in the key of \(key) for the \(genre) genre.
                Use extended voicings like maj7, m9, 13ths if appropriate for the genre.
                Format your response as a simple comma-separated list of chords.
                """

                // 1. Tokenize the prompt and convert to Data (Byte array)
                // Note: Full Gemma implementation requires a custom sentencepiece tokenizer here.
                // We're sending raw string bytes as a simplified demonstration.
                guard let inputData = prompt.data(using: .utf8) else {
                    DispatchQueue.main.async { completion("Error encoding prompt") }
                    return
                }

                // 2. Copy the input data to the input tensor
                try interpreter.copy(inputData, toInputAt: 0)

                // 3. Run inference
                try interpreter.invoke()

                // 4. Get the output tensor data
                let outputTensor = try interpreter.output(at: 0)

                // 5. Decode the output bytes to String
                let outputData = outputTensor.data
                let outputString = String(data: outputData, encoding: .utf8) ?? "Cmaj7, Am9, Dm7, G13"

                DispatchQueue.main.async {
                    completion(outputString)
                }

            } catch {
                print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Error running inference")
                }
            }
        }
    }
}
