import XCTest
@testable import HarmonicFlow

final class ArpeggiatorTests: XCTestCase {

    func testArpeggiatorUpdatesNotes() {
        let arp = Arpeggiator()
        arp.updateNotes([60, 64, 67]) // C major chord

        XCTAssertEqual(arp.notes.count, 3)
        XCTAssertEqual(arp.notes, [60, 64, 67])
    }

    func testArpeggiatorLegatoToggle() {
        let arp = Arpeggiator()
        XCTAssertFalse(arp.isLegatoEnabled)

        arp.isLegatoEnabled = true
        XCTAssertTrue(arp.isLegatoEnabled)
    }
}
