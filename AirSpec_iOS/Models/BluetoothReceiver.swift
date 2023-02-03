/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for connecting to a Bluetooth peripheral and reading its characteristic values.
*/

import CoreBluetooth
import os.log
//import Foundation
//import InfluxDBSwift
//import ArgumentParser
//import InfluxDBSwiftApis

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
    
//    private var backgroundSession: WorkoutDataStore // dummy workoutsession to keep the background mode running
    
    private var logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: BluetoothReceiver.self)
    )
    
    //    let GLASSNAME = "CAPTIVATE"
    //    var statusText:String = ""
    //    var csvText:String = ""

    /// -- BLE connection variables
    weak var delegate: BluetoothReceiverDelegate? = nil
    var centralManager: CBCentralManager!
    private var serviceUUID: CBUUID!
    private var TXcharacteristicUUID: CBUUID!
//    private var RXcharacteristicUUID: CBUUID!
    var sendCharacteristic: CBCharacteristic!
    let GLASSNAME =  "AirSpec"///"CAPTIVATE"
    @Published var glassesData: GlassesData
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    @Published private(set) var isScanning: Bool = false
    var scanToAlert = false
    var mustDisconnect = false
    @Published var discoveredPeripherals = Set<CBPeripheral>()
    /// -- BLE connection variables end
    
    /// -- TCP client to server connection variables
    @Published var connectedToSatServer: Bool = false
    @Published var status: String = ""
    private var satServerClient: NIO_TCP_Client?
    private var notificationServerClient: NIO_TCP_Client?
//    private var influxClient: InfluxDBClient
    @Published var temperatureValue: String = ""
    /// -- TCP client to server connection variables end
    ///
    
    
    init(service: CBUUID, characteristic: CBUUID) {
        self.glassesData = GlassesData(sensorData: "")
//        self.backgroundSession = WorkoutDataStore()
//        self.backgroundSession.startWorkoutSession()
//        self.influxClient = InfluxDBClient(url: NetworkConstants.url, token: NetworkConstants.token)
        super.init()
        self.serviceUUID = service
        self.TXcharacteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
//        self.connectToServer() /// connect to AirSpec 2022 version server
        
    }
    
    /// -- TCP server connection
    func connectToServer() { // called from RootView.onAppwar
        status = "Connecting to AirSpec Server..."
        do {
//            satServerClient = try NIO_TCP_Client.connect(host: NetworkConstants.host, port: NetworkConstants.port) {
//                self.satServerCallback(data: $0)
//            }
            satServerClient = try NIO_TCP_Client.connect(host: NetworkConstants.host, port: NetworkConstants.port)
//            notificationServerClient = try NIO_TCP_Client.connect(host: "127.0.0.1", port: 64237)
            connectedToSatServer = true
            status = "Connected to AirSpec server"
        } catch {
            status = "Unable to connect to AirSpec server"
        }
    }
    
//    /// --- influx query
//    func influxQuery(){
//        let query = """
//                    from(bucket: "\(NetworkConstants.bucket)")
//                    |> range(start: -1h)
//                    |> filter(fn: (r) => r["_measurement"] == "sht45")
//                    |> filter(fn: (r) => r["_field"] == "signal")
//                    |> filter(fn: (r) => r["id"] == "9067133")
//                    |> filter(fn: (r) => r["type"] == "temperature")
//                    |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
//                    |> yield(name: "mean")
//        """
//
//        self.influxClient.queryAPI.query(query: query, org: NetworkConstants.org) { [self] response, error in
//          // Error response
//          if let error = error {
//            print("Error:\n\n\(error)")
//          }
//
//          // Success response
//          if let response = response {
//
//            print("\nSuccess response...\n")
//            do {
//              try response.forEach { record in
////                  logger.info("\t\(record.values["_field"]!): \(record.values["_value"]!)")
//                  self.temperatureValue = "\(record.values["_value"]!)"
//              }
//            } catch {
//               print("Error:\n\n\(error)")
//            }
//          }
//        }
//    }
    
//    func disconnectToServer() {
//        status = "Disconnecting..."
//        if satServerOnline() {
//            satServerClient?.disconnect()
//            connectedToSatServer = false
//        }
//        status = "Disconnected"
//    }
    
    func satServerOnline() -> Bool {
        return satServerClient?.isConnected != nil
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
        
//        logger.info("\(peripheral.name ?? "unnamed peripheral") did update characteristic: \(data)")
//        let value = delegate?.didReceiveData(data) ?? -1
        
        if characteristic.uuid == TXcharacteristicUUID {
            /// Get bytes into string
            let dataReceived = characteristic.value! as NSData
            let sensorString = dataReceived.base64EncodedString()
            let sensorString2 = dataReceived.base64EncodedData()
            self.glassesData.sensorData = sensorString
//            self.sensorData = String(sensorString[40])
            print(self.glassesData.sensorData)
//            let dateFormatter : DateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            let date = Date()
//            let dateString = dateFormatter.string(from: date)
//            let newline = "\(dateString),\(String(describing: sensorString))\n"
//            csvText.append(newline)
//            self.socket.write(string:"Test airspec")
//            self.socket.write(string:self.glassesData.sensorData)
//            print(self.glassesData.sensorData)
            
            /// try to send the airspec server (2022 version)
//            do {
//                try satServerClient?.send(Data(Data(referencing: dataReceived).hexEncodedString().utf8))
//
//            } catch {
//                logger.error("TCP connection problems: \(error).")
//                connectedToSatServer = false
//                ///https://stackoverflow.com/questions/59718703/swift-nio-tcp-client-auto-reconnect
//            }
            
        }
    }
    
//    func testLight() -> String{ /// toggle version
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
    
//    func testLight(){
//
//        do {
//            if connectedPeripheral?.state == CBPeripheralState.connected {
//
//                if let characteristic:CBCharacteristic = sendCharacteristic{
//                    let data: Data = Data("0123456789".utf8) as Data
//                    logger.info("read characteristics \(data)")
//                    connectedPeripheral!.writeValue(data,
//                                            for: characteristic,
//                                         BluetoothReceiver   type: CBCharacteristicWriteType.withoutResponse)
//                    logger.info("read characteristics \(characteristic)")
//                    print("Try to set LED light")
//                }
//            }
//        } catch {
//            print("cannot write to the glasses")
//        }
//    }
}



extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

