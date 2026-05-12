import Foundation

class Arpeggiator {
    var isRunning = false
    var bpm: Double = 120.0
    var notes: [Int] = []

    private var currentIndex = 0
    private var timer: Timer?

    var onNoteTrigger: ((Int) -> Void)?
    var onNoteOff: ((Int) -> Void)?

    private var currentNotePlaying: Int?

    // Legato Mode flag
    var isLegatoEnabled: Bool = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentIndex = 0
        scheduleNextNote()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        if let current = currentNotePlaying {
            onNoteOff?(current)
            currentNotePlaying = nil
        }
    }

    func updateNotes(_ newNotes: [Int]) {
        self.notes = newNotes.sorted()
        // If arpeggiator is running, snap to the nearest note in the new chord immediately
        if isRunning && !notes.isEmpty {
            if currentIndex >= notes.count {
                currentIndex = 0
            }
            triggerCurrentNote()

            // Reschedule timer to maintain rhythm
            timer?.invalidate()
            scheduleNextNote()
        }
    }

    private func scheduleNextNote() {
        guard isRunning else { return }

        // 16th notes
        let interval = (60.0 / bpm) / 4.0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.triggerCurrentNote()

            self.currentIndex += 1
            if self.currentIndex >= self.notes.count {
                self.currentIndex = 0
            }
        }
    }

    private func triggerCurrentNote() {
        guard !notes.isEmpty else { return }
        let nextNote = notes[currentIndex]

        if isLegatoEnabled {
            // Note On first
            onNoteTrigger?(nextNote)

            // Delayed Note Off for the previous note to overlap
            if let prevNote = currentNotePlaying, prevNote != nextNote {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.onNoteOff?(prevNote)
                }
            }
        } else {
            // Standard: Note Off, then Note On
            if let prevNote = currentNotePlaying {
                onNoteOff?(prevNote)
            }
            onNoteTrigger?(nextNote)
        }

        currentNotePlaying = nextNote
    }
}
