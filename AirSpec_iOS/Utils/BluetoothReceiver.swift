/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for connecting to a Bluetooth peripheral and reading its characteristic values.
*/

import CoreBluetooth
import os.log
//import Starscream

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

/// A listener to subscribe to a Bluetooth LE peripheral and get characteristic updates from it.
///
//class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, WebSocketDelegate {
class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
//    private var backgroundSession: WorkoutDataStore // dummy workoutsession to keep the background mode running
    
    private var logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: BluetoothReceiver.self)
    )

    weak var delegate: BluetoothReceiverDelegate? = nil
    
    var centralManager: CBCentralManager!
    
    private var serviceUUID: CBUUID!

    private var characteristicUUID: CBUUID!
    
//    let GLASSNAME = "CAPTIVATE"
    let GLASSNAME = "AirSpec"
    
    var statusText:String = ""
    var csvText:String = ""
    
//    @Published var sensorData:String = ""
    @Published var glassesData: GlassesData
    
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    
    @Published private(set) var isScanning: Bool = false
    
    var scanToAlert = false
    
    var mustDisconnect = false
    
    // connect to the server
//    var socket: WebSocket!
//    var isConnected = false
//    let server = WebSocketServer()
    
    @Published var discoveredPeripherals = Set<CBPeripheral>()
    
    init(service: CBUUID, characteristic: CBUUID) {
        self.glassesData = GlassesData(sensorData: "")
//        self.backgroundSession = WorkoutDataStore()
//        self.backgroundSession.startWorkoutSession()
        super.init()
        self.serviceUUID = service
        self.characteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
//        self.connectToServer()
        
    }
    
    // for the airspec server connection
//    func didReceive(event: WebSocketEvent, client: WebSocket) {
//        switch event {
//        case .connected(let headers):
//            isConnected = true
//            print("websocket is connected: \(headers)")
//        case .disconnected(let reason, let code):
//            isConnected = false
//            print("websocket is disconnected: \(reason) with code: \(code)")
//        case .text(let string):
//            print("Received text: \(string)")
//        case .binary(let data):
//            print("Received data: \(data.count)")
//        case .ping(_):
//            break
//        case .pong(_):
//            break
//        case .viabilityChanged(_):
//            break
//        case .reconnectSuggested(_):
//            break
//        case .cancelled:
//            isConnected = false
//        case .error(let error):
//            isConnected = false
//            handleError(error)
//        }
//    }

    // for connecting to the airspec server
//    func connectToServer(){
//        var request = URLRequest(url: URL(string: "airspecs.media.mit.edu:64235")!)
//        request.timeoutInterval = 5
//        socket = WebSocket(request: request)
//        socket.delegate = self
//        socket.connect()
//        logger.info("connecting to the airspec server")
//    }
//
//    func handleError(_ error: Error?) {
//        if let e = error as? WSError {
//            print("websocket encountered an error: \(e.message)")
//        } else if let e = error {
//            print("websocket encountered an error: \(e.localizedDescription)")
//        } else {
//            print("websocket encountered an error")
//        }
//    }
    
    
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
        peripheral.discoverServices([BluetoothConstants.sampleServiceUUID])
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
        peripheral.discoverCharacteristics([characteristicUUID], for: service)
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

        
        if let characteristic = characteristics.first(where: { $0.uuid == characteristicUUID }) {
            logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
            peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.

//            if #available(watchOS 9.0, *) {
            /// Subscribe to the characteristic.
            peripheral.setNotifyValue(true, for: characteristic)
            logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
//            }
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
        
        if characteristic.uuid == characteristicUUID {
            // Get bytes into string
            let dataReceived = characteristic.value! as NSData
            let sensorString = dataReceived.base64EncodedString()
            self.glassesData.sensorData = sensorString
            //            self.sensorData = String(sensorString[40])
//            print(self.glassesData.sensorData)
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            let newline = "\(dateString),\(String(describing: sensorString))\n"
            csvText.append(newline)
//            self.socket.write(string:"Test airspec")
//            self.socket.write(string:self.glassesData.sensorData)
            print(self.glassesData.sensorData)
//            do {
//                // Create audio player object
//                try self.socket.write(string:self.glassesData.sensorData)
//                print(self.glassesData.sensorData)
//            }
//            catch {
//                // Couldn't create audio player object, log the error
//                print("Socket connection problems")
//            }
            
        }
    }
}

//extension BluetoothReceiver{
//    func placeholder() -> String{
//        BluetoothReceiver(service: BluetoothConstants.sampleServiceUUID, characteristic: BluetoothConstants.sampleCharacteristicUUID).sensorData
//    }
//}

