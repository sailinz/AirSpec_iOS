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
    let GLASSNAME = "AirSpec"
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
    /// -- TCP client to server connection variables end
    
    
    
    init(service: CBUUID, characteristic: CBUUID) {
        self.glassesData = GlassesData(sensorData: "")
//        self.backgroundSession = WorkoutDataStore()
//        self.backgroundSession.startWorkoutSession()
        super.init()
        self.serviceUUID = service
        self.TXcharacteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.connectToServer()
        
    }
    
    /// -- TCP server connection
    func connectToServer() { // called from RootView.onAppwar
        status = "Connecting to AirSpec Server..."
        do {
//            satServerClient = try NIO_TCP_Client.connect(host: NetworkConstants.host, port: NetworkConstants.port) {
//                self.satServerCallback(data: $0)
//            }
            satServerClient = try NIO_TCP_Client.connect(host: NetworkConstants.host, port: NetworkConstants.port)
            connectedToSatServer = true
            status = "Connected to AirSpec server"
        } catch {
            status = "Unable to connect to AirSpec server"
        }
    }
    
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
        peripheral.discoverCharacteristics([TXcharacteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(where: { $0.uuid == serviceUUID }) {
            logger.info("\(peripheral.name ?? "unnamed peripheral") did invalidate service \(self.serviceUUID)")
            disconnect(from: peripheral, mustDisconnect: true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error? ) {
        if let error = error {
            logger.error("error discovering characteristic: \(error.localizedDescription)")
            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
            return
        }
        
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            logger.info("no characteristics discovered on \(peripheral.name ?? "unnamed peripheral") for service \(service.description)")
            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
            return
        }
        
//        if let characteristic = characteristics.first(where: { $0.uuid == TXcharacteristicUUID }) {
//            logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//            peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.
//
//            /// Subscribe to the characteristic.
//            peripheral.setNotifyValue(true, for: characteristic)
//            logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//        }
        
        for characteristic in service.characteristics! {
//            print(characteristic)
            if characteristic.uuid == BluetoothConstants.airspecTXCharacteristicUUID{
                    logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
                    peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.
                    /// Subscribe to the characteristic.
                    peripheral.setNotifyValue(true, for: characteristic)
                    logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
                 }

                if characteristic.uuid == BluetoothConstants.airspecRXCharacteristicUUID{
                    let thisCharacteristic = characteristic as CBCharacteristic
                    sendCharacteristic = thisCharacteristic
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
        
        logger.info("\(peripheral.name ?? "unnamed peripheral") did update characteristic: \(data)")
//        let value = delegate?.didReceiveData(data) ?? -1
        
        if characteristic.uuid == TXcharacteristicUUID {
            /// Get bytes into string
            let dataReceived = characteristic.value! as NSData
            let sensorString = dataReceived.base64EncodedString()
            let sensorString2 = dataReceived.base64EncodedData()
            self.glassesData.sensorData = sensorString
//            self.sensorData = String(sensorString[40])
//            print(self.glassesData.sensorData)
//            let dateFormatter : DateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            let date = Date()
//            let dateString = dateFormatter.string(from: date)
//            let newline = "\(dateString),\(String(describing: sensorString))\n"
//            csvText.append(newline)
//            self.socket.write(string:"Test airspec")
//            self.socket.write(string:self.glassesData.sensorData)
//            print(self.glassesData.sensorData)
            
            do {
//                try satServerClient?.send(Data(self.glassesData.sensorData.utf8))
                try satServerClient?.send(Data(Data(referencing: dataReceived).hexEncodedString().utf8))
//                try satServerClient?.send(Data(referencing: dataReceived))
//                print(self.glassesData.sensorData)
            } catch {
                logger.error("TCP connection problems: \(error).")
                connectedToSatServer = false
                ///https://stackoverflow.com/questions/59718703/swift-nio-tcp-client-auto-reconnect 
            }
            
        }
    }
    
    func testLight(){
        print("Try to set LED light")
        do {
            if connectedPeripheral?.state == CBPeripheralState.connected {
                if let characteristic:CBCharacteristic = sendCharacteristic{
                    let data: Data = Data("ABCD".utf8) as Data
                        try connectedPeripheral?.writeValue(data,
                                            for: characteristic,
                                            type: CBCharacteristicWriteType.withResponse)
                }
            }
        } catch {
            print("cannot write to the glasses")
        }
        
    }
}



extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

