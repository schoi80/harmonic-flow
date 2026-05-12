import Foundation
import CoreMIDI
import CoreBluetooth

class MIDIManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    // Network RTP MIDI
    var midiClient: MIDIClientRef = 0
    var midiOutPort: MIDIPortRef = 0
    var virtualEndpoint: MIDIEndpointRef = 0

    // BLE MIDI
    var peripheralManager: CBPeripheralManager!
    var midiCharacteristic: CBMutableCharacteristic?

    // Apple's standard BLE MIDI Service UUID
    let midiServiceUUID = CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
    let midiCharacteristicUUID = CBUUID(string: "7772E5DB-3868-4112-A1A9-F2669D106BF3")

    override init() {
        super.init()
        setupNetworkMIDI()
        setupBLEMIDI()
    }

    private func setupNetworkMIDI() {
        var status = MIDIClientCreate("HarmonicFlowClient" as CFString, nil, nil, &midiClient)
        if status != noErr { print("Error creating MIDI client"); return }

        status = MIDIOutputPortCreate(midiClient, "HarmonicFlowOutPort" as CFString, &midiOutPort)
        if status != noErr { print("Error creating MIDI out port"); return }

        status = MIDISourceCreate(midiClient, "HarmonicFlow Network" as CFString, &virtualEndpoint)
        if status != noErr { print("Error creating MIDI source"); return }

        MIDINetworkSession.default().isEnabled = true
        MIDINetworkSession.default().connectionPolicy = .anyone
    }

    private func setupBLEMIDI() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    // MARK: - CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let characteristic = CBMutableCharacteristic(
                type: midiCharacteristicUUID,
                properties: [.read, .writeWithoutResponse, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            self.midiCharacteristic = characteristic

            let service = CBMutableService(type: midiServiceUUID, primary: true)
            service.characteristics = [characteristic]

            peripheralManager.add(service)
            peripheralManager.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [midiServiceUUID],
                CBAdvertisementDataLocalNameKey: "HarmonicFlow BLE"
            ])
            print("BLE MIDI Advertising started")
        }
    }

    // MARK: - Sending MIDI

    func sendNoteOn(note: Int, velocity: Int, channel: UInt8 = 0) {
        let status = UInt8(0x90) + channel
        sendMIDIData(bytes: [status, UInt8(note), UInt8(velocity)])
    }

    func sendNoteOff(note: Int, channel: UInt8 = 0) {
        let status = UInt8(0x80) + channel
        sendMIDIData(bytes: [status, UInt8(note), 0])
    }

    func sendControlChange(cc: UInt8, value: UInt8, channel: UInt8 = 0) {
        let status = UInt8(0xB0) + channel
        sendMIDIData(bytes: [status, cc, value])
    }

    private func sendMIDIData(bytes: [UInt8]) {
        // 1. Send via Network RTP
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        _ = MIDIPacketListAdd(&packetList, 1024, packet, mach_absolute_time(), bytes.count, bytes)
        MIDIReceived(virtualEndpoint, &packetList)

        // 2. Send via BLE
        guard let char = midiCharacteristic, peripheralManager.state == .poweredOn else { return }

        // BLE MIDI Packet wrapping (simplified)
        // [Header Byte (Timestamp high), Timestamp Low, Status, Data1, Data2]
        var bleBytes: [UInt8] = [0x80, 0x80] // Mock timestamp bytes for simplicity
        bleBytes.append(contentsOf: bytes)

        let data = Data(bleBytes)
        peripheralManager.updateValue(data, for: char, onSubscribedCentrals: nil)
    }
}
