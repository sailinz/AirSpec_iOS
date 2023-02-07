/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for connecting to a Bluetooth peripheral and reading its characteristic values.
*/

import CoreBluetooth
import os.log

protocol BluetoothReceiverDelegate: AnyObject {
    func didReceiveData(_ message: Data) -> Int
    func didCompleteDisconnection(from peripheral: CBPeripheral, mustDisconnect: Bool)
    func didFailWithError(_ error: BluetoothReceiverError)
}

enum BluetoothReceiverError: Error {
    case failedToConnect
    case failedToDiscoverCharacteristics
    case failedToDiscoverServices
    case failedToReceiveCharacteristicUpdate
}

/// A listener to subscribe to a Bluetooth LE peripheral and get characteristic updates the data to a TCP server.
///
class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: BluetoothReceiver.self)
    )

    /// -- BLE connection variables
    weak var delegate: BluetoothReceiverDelegate? = nil
    var centralManager: CBCentralManager!
    private var serviceUUID: CBUUID!
    private var TXcharacteristicUUID: CBUUID!
    var sendCharacteristic: CBCharacteristic!
    let GLASSNAME =  "AirSpec"///"CAPTIVATE"
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    @Published private(set) var isScanning: Bool = false
    var scanToAlert = false
    var mustDisconnect = false
    @Published var discoveredPeripherals = Set<CBPeripheral>()
    /// -- BLE connection variables end
    ///
    /// -- realtime sensor data
    @Published var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
    @Published var airQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
    @Published var visualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
    @Published var acoutsticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)
    
    @Published var cogIntensity = 1 /// must scale to a int

    /// -- watchConnectivity
//    @Published var prog : ProgramObject
//    let viewModel = ProgramViewModel(connectivityProvider: ConnectionProvider())
//    let connect = ConnectionProvider()
    @Published var dataToWatch = SensorData()
//    @Published var temperatureData = TemperatureData()
//    @Published var co2Data = CO2Data()
//    @Published var vocIndexData = VOCIndexData()
    
    init(service: CBUUID, characteristic: CBUUID) {
        super.init()
        self.serviceUUID = service
        self.TXcharacteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
//        connect.connect()
    }

    /// -- BLE connection
    func startScanning() {
        logger.info("scanning for new peripherals with service") // \(self.serviceUUID)
        centralManager.scanForPeripherals(withServices: nil, options: nil)

        discoveredPeripherals.removeAll()
        isScanning = true
    }

    func stopScanning() {
        logger.info("stopped scanning for new peripherals")
        centralManager.stopScan()
        isScanning = false
    }

    func connect(to peripheral: CBPeripheral) {
        if let connectedPeripheral = connectedPeripheral {
            disconnect(from: connectedPeripheral, mustDisconnect: true)
        }
        print("try to connect")

        logger.info("connecting to \(peripheral.name ?? "unnamed peripheral")")
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)

    }

    func disconnect(from peripheral: CBPeripheral, mustDisconnect: Bool) {
        logger.info("disconnecting from \(peripheral.name ?? "unnamed peripheral")")
        self.mustDisconnect = mustDisconnect
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        logger.log("central state is: \(state.rawValue)")

        if state == .poweredOn {
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber ) {
        let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString

        if device?.contains(GLASSNAME) == true {
            discoveredPeripherals.insert(peripheral)
            peripheral.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("failed to connect to \(peripheral.name ?? "unnamed peripheral")")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("connected to \(peripheral.name ?? "unnamed peripheral")")
        discoveredPeripherals.remove(peripheral)
        connectedPeripheral = peripheral
        knownDisconnectedPeripheral = nil
        peripheral.discoverServices([BluetoothConstants.airspecServiceUUID])
    }

    /// If the app wakes up to handle a background refresh task, the system calls this method if
    /// a peripheral disconnects when the app transitions to the background.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("disconnected from \(peripheral.name ?? "unnamed peripheral")")
        connectedPeripheral = nil

        /// Keep track of the last known peripheral.
        knownDisconnectedPeripheral = peripheral

        delegate?.didCompleteDisconnection(from: peripheral, mustDisconnect: self.mustDisconnect)
        self.mustDisconnect = false
    }

    // MARK: CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("error discovering service: \(error.localizedDescription)")
            delegate?.didFailWithError(.failedToDiscoverServices)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            logger.info("no valid services on \(peripheral.name ?? "unnamed peripheral")")
            delegate?.didFailWithError(.failedToDiscoverServices)
            return
        }

        logger.info("discovered service \(service.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//        peripheral.discoverCharacteristics([TXcharacteristicUUID, ], for: service)
        peripheral.discoverCharacteristics(nil, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(where: { $0.uuid == serviceUUID }) {
            logger.info("\(peripheral.name ?? "unnamed peripheral") did invalidate service \(self.serviceUUID)")
            disconnect(from: peripheral, mustDisconnect: true)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error? ) {
//        if let error = error {
//            logger.error("error discovering characteristic: \(error.localizedDescription)")
//            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
//            return
//        }
//
//        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
//            logger.info("no characteristics discovered on \(peripheral.name ?? "unnamed peripheral") for service \(service.description)")
//            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
//            return
//        }

//        if let characteristic = characteristics.first(where: { $0.uuid == TXcharacteristicUUID }) {
//            logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//            peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.
//
//            /// Subscribe to the characteristic.
//            peripheral.setNotifyValue(true, for: characteristic)
//            logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//        }
        logger.info("service UUID: \(service.uuid)")
        logger.info("total no. of characteristics: \(service.characteristics!.count)")


        for characteristic in service.characteristics! {
            logger.info("characteristic:  \(characteristic.uuid)")
            if characteristic.uuid == BluetoothConstants.airspecTXCharacteristicUUID{
                logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
                peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.
                /// Subscribe to the characteristic.
                peripheral.setNotifyValue(true, for: characteristic)
                logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
            } else if (characteristic.uuid == BluetoothConstants.airspecRXCharacteristicUUID) {
                let thisCharacteristic = characteristic as CBCharacteristic
                sendCharacteristic = thisCharacteristic
                logger.info("found write characteristics")


            }

        }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.error("\(peripheral.name ?? "unnamed peripheral") failed to update value: \(error!.localizedDescription)")
            delegate?.didFailWithError(.failedToReceiveCharacteristicUpdate)
            return
        }

        guard let data = characteristic.value else {
            logger.warning("characteristic value from \(peripheral.name ?? "unnamed peripheral") is nil")
            delegate?.didFailWithError(.failedToReceiveCharacteristicUpdate)
            return
        }

        if characteristic.uuid == TXcharacteristicUUID {


            do {
                guard let packet = try? Airspec.decode_packet(data) else {
                    print("failed parsing packet: \(error)")
                    return
                }
//                print(packet)
                
//                viewModel.connectivityProvider.connect()

                if(packet.hasBmePacket){
                    for sensorPayload in packet.bmePacket.payload {
                        if(sensorPayload.sensorID == 3){
                            self.airQualityData[2] = Double(sensorPayload.signal) /// CO2
                            dataToWatch.updateValue(sensorValue: self.airQualityData[2], sensorName: "co2Data")
                        }else if(sensorPayload.sensorID == 1){
                            self.airQualityData[3] = Double(sensorPayload.signal) /// IAQ
                            dataToWatch.updateValue(sensorValue: self.airQualityData[3], sensorName: "iaqData")
                        }
                    }
                }else if(packet.hasLuxPacket){
                    print("lux: ", packet.luxPacket)
                    for sensorPayload in packet.luxPacket.payload {
                        if(sensorPayload.lux != nil){
                            self.visualData[0] = Double(sensorPayload.lux) /// lux
                            dataToWatch.updateValue(sensorValue: self.visualData[0], sensorName: "luxData")
                        }
                    }
                }else if(packet.hasShtPacket){
                    print("sht: ", packet.shtPacket)
                    for sensorPayload in packet.shtPacket.payload {
                        if(sensorPayload.temperature != nil && sensorPayload.humidity != nil){
                            self.thermalData[0] = Double(sensorPayload.temperature) /// temperature
                            dataToWatch.updateValue(sensorValue: self.thermalData[0], sensorName: "temperatureData")
                            self.thermalData[1] = Double(sensorPayload.humidity) /// humidity
//                            dataToWatch.updateValue(sensorValue: self.thermalData[1], sensorName: "humidityData")
                            
                        }
                    }
                    
                }else if(packet.hasSgpPacket){
                    for sensorPayload in packet.sgpPacket.payload {
                        if(sensorPayload.vocIndexValue != nil && sensorPayload.noxIndexValue != nil){
                            self.airQualityData[0] = Double(sensorPayload.vocIndexValue) /// voc index
                            dataToWatch.updateValue(sensorValue: self.airQualityData[0], sensorName: "vocIndexData")
                            self.airQualityData[1] = Double(sensorPayload.noxIndexValue) /// nox index
                            dataToWatch.updateValue(sensorValue: self.airQualityData[1], sensorName: "noxIndexData")
//                            print(sensorPayload)
                        }
                    }
                    
                }else if(packet.hasMicPacket){
                    // tbd
                    
                }else if(packet.hasThermPacket){
                    var thermNoseTip: Double
                    var thermNoseBridge: Double
                    var thermNoseFront: Double
                    var thermNoseMiddle: Double
                    var thermNoseBack: Double

                    for sensorPayload in packet.thermPacket.payload {
                        if(sensorPayload.descriptor == 1){
                            thermNoseTip = Double(sensorPayload.objectTemp)
                        }else if(sensorPayload.descriptor == 2){
                            thermNoseBridge = Double(sensorPayload.objectTemp)
                        }else if(sensorPayload.descriptor == 3){
                            thermNoseFront = Double(sensorPayload.objectTemp)
                        }else if(sensorPayload.descriptor == 4){
                            thermNoseMiddle = Double(sensorPayload.objectTemp)
                        }else if(sensorPayload.descriptor == 5){
                            thermNoseBack = Double(sensorPayload.objectTemp)
                        }else{
                            
                        }
                    }
                    
                    cogIntensity = Int(abs((thermNoseFront + thermNoseMiddle + thermNoseBack)/3 - (thermNoseTip + thermNoseBridge)/2)*10+5) /// temple - face
                    
                }else{
//                    print(packet)
                }
                
                
                try Airspec.send_packets(packets: [packet], auth_token: "")

            } catch {
                logger.error("packet decode/send problems: \(error).")
            }

        }
    }

    func testLight(){
        /// https://stackoverflow.com/questions/57985152/how-to-write-a-value-to-characteristc-for-ble-device-in-ios-swift
        /// Bytes are read from right to left, like german language
//        var headerBytes: [UInt8] = [0x01, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00] ///  first two byptes: 01 - control LED; byte 3-4: 18 - LED payload size; last 4 bytes: timestamp - to be updated below
        /// [packet type byte 0, packet type byte 1, , payload size byte 0, payload size byte 1, unix timestamp, unix timestamp, unix timestamp, unix timestamp] Hex e.g, 18 to be dec and hex is 0x00, 0x12 (we'll see the 0012 as transfered hex value)
        ///
        //      let payloadBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC8, 0x00, 0x00, 0x00, 0x00, 0xC8, 0x00, 0x00, 0x00, 0x00, 0x00]
//        let payloadBytes: [UInt8] = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50] /// all white on


        /// Blue-Green Transition mode
        var headerBytes: [UInt8] = [0x05, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00]
        let payloadBytes: [UInt8] = [0x02, 0x01, 0x32, 0xFF, 0xFF, 0x0A, 0x64]
        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampArray = withUnsafeBytes(of: timestamp.bigEndian, Array.init)
//        print(timestamp)
//        print(timestampArray)
        headerBytes[4] = timestampArray[7]
        headerBytes[5] = timestampArray[6]
        headerBytes[6] = timestampArray[5]
        headerBytes[7] = timestampArray[4]
        print(headerBytes)
        /// 18 bytes payload. everyone is up to 255 in decimal -> no need to convert to hex and change the corresponding byte; all 0 is a LED off; 0xFF is fully on
        let cmd = Data(headerBytes + payloadBytes)
        connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
//        return "" /// toggle version
    }

    func testLightReset(){
        /// https://stackoverflow.com/questions/57985152/how-to-write-a-value-to-characteristc-for-ble-device-in-ios-swift
        /// Bytes are read from right to left, like german language
        var headerBytes: [UInt8] = [0x01, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00]
        let payloadBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] /// all off

        /// Blue-Green Transition mode
//        var headerBytes: [UInt8] = [0x05, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00]
//        let payloadBytes: [UInt8] = [0x02, 0x01, 0x32, 0xFF, 0xFF, 0x0A, 0x0A]

        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampArray = withUnsafeBytes(of: timestamp.bigEndian, Array.init)

        headerBytes[4] = timestampArray[7]
        headerBytes[5] = timestampArray[6]
        headerBytes[6] = timestampArray[5]
        headerBytes[7] = timestampArray[4]
        print(headerBytes)

        let cmd = Data(headerBytes + payloadBytes)
        connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
    }
}



extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

