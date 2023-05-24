//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin and Nathan PERRY on 14.02.23.

import CoreBluetooth
import os.log
import CoreData
import CoreLocation
import DequeModule
import RealmSwift

enum BluetoothReceiverError: Error {
    case failedToConnect
    case failedToDiscoverCharacteristics
    case failedToDiscoverServices
    case failedToReceiveCharacteristicUpdate
}

let AUTH_TOKEN = "4129a31152b56fccfb8b39cab3637706aa5e5f4ded601c45313cd4f7170fc702"

func timestamp_now() -> UInt64 {
    let now_date = Date()
    let now = UInt64(now_date.timeIntervalSince1970 * 1000)
    print("setting ts now: \(now_date): \(now)")
    return now
}

/// A listener to subscribe to a Bluetooth LE peripheral and get characteristic updates the data to a TCP server.
///
class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum State {
        case connected
        case scanning
        case disconnectedWithPeripheral
        case disconnectedWithoutPeripheral
    }
    
    private var logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: BluetoothReceiver.self)
    )
    
    /// -- BLE CONNNECTION VARIABLES
    var centralManager: CBCentralManager!
    var sendCharacteristic: CBCharacteristic!
    @Published var GLASSNAME: String?
    @Published private(set) var peripheral: CBPeripheral? = nil
    
    var scanToAlert = false
    
    /// -- REAL-TIME SENSOR DATA
    @Published var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
    @Published var airQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
    @Published var visualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
    @Published var acoutsticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)
    
    @Published var cogIntensity = 3 /// must scale to a int
    let cogLoadOffset: Double = 2
    let cogLoadMultiFactor: Double = 5
    
    @Published var cmDirty: Bool = false
    
    var sgpSidePacketID: Int?
    var sgpNosePacketID: Int?
    var bmePacketID: Int?
    var luxPacketID: Int?
    var luxPacketIDCoredata: Int?
    var luxPacketIDQueue: Int?
    var shtSidePacketID: Int?
    var shtNosePacketID: Int?
    var specPacketID: Int?
    var thermPacketID: Int?
    
    
    var prevBMEIndex: Int = 0
    
    
    var state: State {
        get {
            if (peripheral == nil) {
                return .disconnectedWithoutPeripheral
            }
            
            let connected = centralManager.retrieveConnectedPeripherals(withServices: [BluetoothConstants.airspecServiceUUID])
            if (connected.contains(where: {$0 == peripheral})) {
                return .connected
            }
            
            if (centralManager.isScanning) {
                return .scanning
            }
            
            return .disconnectedWithPeripheral
        }
    }
    
    /// -- WATCH CONNECTIVITY
    @Published var dataToWatch = SensorData()
    @Published var isBlueGreenSurveyDone = false
    //    var surveyStatusFromWatch = SensorData()
    
    /// -- NOTIFICATION MECHENISM
    /// maybe the sampling frequency is high enough that the location information is not needed
    //    let locationManager = CLLocationManager()
    //    var previousLocation: CLLocation?
    //    var prevNotificationTime: Date = Date().addingTimeInterval(-60*60)
    var randomNextNotificationGap: Int = 30 /// minute
    var notificationTimer:DispatchSourceTimer?
    let greenHoldTime = 60 * 15 /// sec
    let maxIntensity: UInt32 = 9
    var disconnectionTimer:DispatchSourceTimer?
    
    /// -- PUSH TO THE SERVER
    private var timer: DispatchSourceTimer?
    let updateFrequence = 20 /// seconds
    var countUpdateFrequency = 0
    var isUploadToServer = false
//    var tempPacketBuffer:[SensorPacket] = []
//    var countPackets = 0
    var rawDataQueue: Deque<Data> = []
    
    let rawDataSync = DispatchQueue(label: "raw_data_queue")
    
    /// alternative realm database only for raw sensor data
//    var realm: Realm = try! Realm()
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setTargetId(_ glasses_id: String) {
        GLASSNAME = glasses_id
        
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        peripheral = nil
        scan()
    }
    
    func toggle() {
        let periphs = centralManager.retrieveConnectedPeripherals(withServices: [BluetoothConstants.airspecServiceUUID])
        
        if centralManager.isScanning || periphs.contains(where: { $0 == peripheral }) {
            disconnect()
        } else {
            start_connect()
        }
    }
    
    func invalidateId() {
        disconnect()
        peripheral = nil
    }
    
    func start_connect() {
        if let peripheral = peripheral {
            centralManager.connect(peripheral)
            return
        }
        
        scan()
    }
    
    func scan() {
        logger.info("scanning for new peripherals")
        centralManager.scanForPeripherals(withServices: [BluetoothConstants.airspecServiceUUID], options: nil)
    }
    
    func disconnect() {
        centralManager.stopScan()
        
        guard let peripheral = self.peripheral else {
            logger.warning("trying to disconnect from nonexistent peripheral")
            return
        }
        
        logger.info("disconnecting from \(peripheral.name ?? "unnamed peripheral")")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        defer { cmDirty.toggle() }
        
        if central.state == .poweredOn {
            start_connect()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        defer { cmDirty.toggle() }
        
        guard let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString else {
            return
        }
        
        guard let glassname = GLASSNAME else {
            return
        }
        
        if !device.contains(glassname) {
            return
        }
        
        centralManager.stopScan()
        
        logger.info("BLE connected")
        
        self.peripheral = peripheral
        peripheral.delegate = self
        
        centralManager.connect(peripheral)
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        defer { cmDirty.toggle() }
        logger.error("failed to connect to \(peripheral.name ?? "unnamed peripheral")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        defer { cmDirty.toggle() }
        logger.info("connected to \(peripheral.name ?? "unnamed peripheral")")
        peripheral.discoverServices([BluetoothConstants.airspecServiceUUID])
        
        RawDataViewModel.addMetaDataToRawData(payload: "connected to \(peripheral.name ?? "unnamed peripheral")", timestampUnix: Date(), type: 5)
        disconnectionTimer?.cancel()
        disconnectionTimer = nil
        
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now() + .seconds(10), repeating: .seconds(updateFrequence))
        timer?.setEventHandler {
            
            self.countUpdateFrequency += 1
            
            if self.countUpdateFrequency % 3 == 0{ /// upload to server every 1 minute
                self.uploadToServer()
            }else{
                self.addDatafromQueueToRawDataDB()
            }
            
            if self.countUpdateFrequency == 15 { /// local avg every 5 min
                self.countUpdateFrequency = 0
//                self.uploadToServer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 9)  { /// wait for 9 sec
                    self.storeLongTermData()
                }
            }
//            else{
//                self.addDatafromQueueToRawDataDB()
//            }
            
            
//            self.isUploadToServer = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5)  { /// wait for 3 sec
//                self.uploadToServer()
//            }
//
//            self.countUpdateFrequency = self.countUpdateFrequency + 1
//            if self.countUpdateFrequency == 5 {
//                self.countUpdateFrequency = 0
//                DispatchQueue.main.asyncAfter(deadline: .now() + 20)  { /// wait for 3 sec
//                    self.storeLongTermData()
//                }
//            }
        }
        timer?.resume()
    }
    
    /// If the app wakes up to handle a background refresh task, the system calls this method if
    /// a peripheral disconnects when the app transitions to the background.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        defer { cmDirty.toggle() }
        logger.info("disconnected from \(peripheral.name ?? "unnamed peripheral")")
        
        RawDataViewModel.addMetaDataToRawData(payload: "disconnected from \(peripheral.name ?? "unnamed peripheral")", timestampUnix: Date(), type: 5)
        
        disconnectionTimer = DispatchSource.makeTimerSource()
        disconnectionTimer?.schedule(deadline: .now() + .seconds(180), repeating: .seconds(updateFrequence))
        disconnectionTimer?.setEventHandler {
            LocalNotification.setLocalNotification(title: "Is glasses connected?",
                                                   subtitle: "Please check glasses connectivity",
                                                   body: "Open AirSpec App on phone, reboot the glasses if needed.",
                                                   when: 1) /// now
        }
        disconnectionTimer?.resume()
        
        /// stop data stream to the server
        timer?.cancel()
        timer = nil
        
        scan()
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("error discovering service: \(error.localizedDescription)")
            return
        }
        
        guard let service = peripheral.services?.first(where: { $0.uuid == BluetoothConstants.airspecServiceUUID }) else {
            logger.info("no valid services on \(peripheral.name ?? "unnamed peripheral")")
            return
        }
        
        logger.info("discovered service \(service.uuid) on \(peripheral.name ?? "unnamed peripheral")")
        peripheral.discoverCharacteristics([BluetoothConstants.airspecTXCharacteristicUUID, BluetoothConstants.airspecRXCharacteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if !invalidatedServices.contains(where: { $0.uuid == BluetoothConstants.airspecServiceUUID }) {
            return
        }
        
        logger.info("\(peripheral.name ?? "unnamed peripheral") did invalidate service")
        disconnect()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error? ) {
        logger.info("service UUID: \(service.uuid)")
        logger.info("total no. of characteristics: \(service.characteristics!.count)")
        
        if let txchar = service.characteristics?.first(where: { $0.uuid == BluetoothConstants.airspecTXCharacteristicUUID }) {
            peripheral.setNotifyValue(true, for: txchar)
            logger.info("set notify for tx characteristic")
        }
        
        if let rxchar = service.characteristics?.first(where: { $0.uuid == BluetoothConstants.airspecRXCharacteristicUUID }) {
            logger.info("got rx characteristic")
            logger.info("got rx characteristic")
            
            sendCharacteristic = rxchar
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3)  { /// wait for 3 sec
                self.setBlueInit()
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.error("\(peripheral.name ?? "unnamed peripheral") failed to update value: \(error!.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            logger.warning("characteristic value from \(peripheral.name ?? "unnamed peripheral") is nil")
            return
        }
        
        if characteristic.uuid != BluetoothConstants.airspecTXCharacteristicUUID {
            return
        }
        do {
            guard let packet = try? Airspec.decode_packet(data) else {
                print("failed parsing packet: \(error)")
//                RawDataViewModel.addMetaDataToRawData(payload: "failed parsing packet: \(error) ", timestampUnix: Date(), type: 2)
                return
            }
//            print(packet)
            
            /// directly send
//            do {
//                var err: Error?
//                print(packet)
//                try Airspec.send_packets(packets: [packet], auth_token: AUTH_TOKEN) { error in
//                    err = error
//                }
//
//                if let err = err {
//                    throw err
//                }
//            } catch {
//                RawDataViewModel.addMetaDataToRawData(payload: "cannot upload the data to the server: \(error)", timestampUnix: Date(), type: 2)
//            }
            
            let noHighFreq = try RawDataViewModel.shouldDisableHighFrequency()
            var isHighFreq = false
            
            
            
            switch packet.payload {
            case .some(.blinkPacket(_)):
                isHighFreq = true
                break

            case .some(.imuPacket(_)):
                isHighFreq = true
                
                break
                
            default:
                break
            }
            
            /// using queue
            if (data.isEmpty || isHighFreq && noHighFreq) {
                return
            } else {
                DispatchQueue.global().async { [self] in
                    rawDataSync.sync {
                        
                        rawDataQueue.append(data)
                        
                        
                    }
                }
            }
            
            if(dataToWatch.surveyDone){
                var secondsBetweenDates = Double(greenHoldTime + 12)
                if let prevNotificationTime = UserDefaults.standard.object(forKey: "prevNotificationTime") as? Date{
                    secondsBetweenDates = Date().timeIntervalSince(prevNotificationTime)
                }
                
                
                dataToWatch.surveyDone = false
                notificationTimer?.cancel()
                notificationTimer = nil
                
                
                if(!isBlueGreenSurveyDone){
                    blueGreenLight(isEnable: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3)  { /// wait for 3 sec
                        self.setBlue()
                    }
                    RawDataViewModel.addMetaDataToRawData(payload: "Reaction time: \(secondsBetweenDates); Time now: \(Date()); PrevNotification: \(UserDefaults.standard.object(forKey: "prevNotificationTime")); survey received from watch; reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                    
                }else{
                    RawDataViewModel.addMetaDataToRawData(payload: "Survey received from watch (without blue-green transition); reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                }
                
            }
            
            if(dataToWatch.isEyeCalibrationDone){
                //blueGreenLight(isEnable: false)
                setBlue()
                dataToWatch.isEyeCalibrationDone = false
                RawDataViewModel.addMetaDataToRawData(payload: "eye calibration started", timestampUnix: Date(), type: 2)
            }
            
        
            
            switch packet.payload{
            case .some(.sgpPacket(_)):
//                for sensorPayload in packet.sgpPacket.payload {
//                print(packet)
                if let sensorPayload = packet.sgpPacket.payload.last{
                    if packet.sgpPacket.sensorID == 0 {
                        if(sensorPayload.vocIndexValue != nil && sensorPayload.noxIndexValue != nil){
                            self.airQualityData[3] = Double(sensorPayload.vocIndexValue) /// voc index nose
                            dataToWatch.updateValue(sensorValue: self.airQualityData[3], sensorName: "vocIndexData")
                            self.airQualityData[4] = Double(sensorPayload.noxIndexValue) /// nox index nose
                            dataToWatch.updateValue(sensorValue: self.airQualityData[4], sensorName: "noxIndexData")
                            
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[3].name, value: Float(self.airQualityData[3]))
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[4].name, value: Float(self.airQualityData[4]))
                        }
                    }else{
                        if(sensorPayload.vocIndexValue != nil && sensorPayload.noxIndexValue != nil){
                            self.airQualityData[0] = Double(sensorPayload.vocIndexValue) /// voc index nose
                            dataToWatch.updateValue(sensorValue: self.airQualityData[0], sensorName: "vocIndexAmbientData")
                            self.airQualityData[1] = Double(sensorPayload.noxIndexValue) /// nox index nose
                            dataToWatch.updateValue(sensorValue: self.airQualityData[1], sensorName: "noxIndexAmbientData")
                            
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[0].name, value: Float(self.airQualityData[0]))
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[1].name, value: Float(self.airQualityData[1]))

                        }
                    }
                }
                
//                }
            case .some(.bmePacket(_)):
//                let sensorPayload = packet.bmePacket.payload[0]
                for sensorPayload in packet.bmePacket.payload {
                    if(sensorPayload.sensorID == BME680_signal_id.co2Eq){
                        self.airQualityData[2] = Double(sensorPayload.signal) /// CO2
                        dataToWatch.updateValue(sensorValue: self.airQualityData[2], sensorName: "co2Data")
                    }else if(sensorPayload.sensorID == BME680_signal_id.iaq){
                        self.airQualityData[5] = Double(sensorPayload.signal) /// IAQ
                        dataToWatch.updateValue(sensorValue: self.airQualityData[5], sensorName: "iaqData")
                        
                        try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[2].name, value: Float(self.airQualityData[2]))
                        try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[5].name, value: Float(self.airQualityData[5]))
                    }
                }
                          
            case .some(.luxPacket(_)):
                if let sensorPayload = packet.luxPacket.payload.last{
    //                for sensorPayload in packet.luxPacket.payload {
                    if(sensorPayload.lux != nil){
                        self.visualData[0] = Double(sensorPayload.lux) /// lux
                        dataToWatch.updateValue(sensorValue: self.visualData[0], sensorName: "luxData")
                        dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueLightIntensity")), sensorName: "minValueLightIntensity")
                        dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueLightIntensity")), sensorName: "maxValueLightIntensity")
                        try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorVisual[0].name, value: Float(self.visualData[0]))
                        
                    }
    //                }
                }

                
                
            case .some(.shtPacket(_)):
//                for sensorPayload in packet.shtPacket.payload {
                if let sensorPayload = packet.shtPacket.payload.last{
                    if packet.shtPacket.sensorID == 0 {
                        if(sensorPayload.temperature != nil && sensorPayload.humidity != nil){
                            self.visualData[1] = Double(sensorPayload.temperature) - 5.5 /// temperature
                            dataToWatch.updateValue(sensorValue: self.visualData[1], sensorName: "temperatureData")
                            self.visualData[2] = Double(sensorPayload.humidity) /// humidity
                            dataToWatch.updateValue(sensorValue: self.visualData[2], sensorName: "humidityData")
                            
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueTemp")), sensorName: "minValueTemp")
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueTemp")), sensorName: "maxValueTemp")
                            
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueHum")), sensorName: "minValueHum")
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueHum")), sensorName: "maxValueHum")
                            
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorVisual[1].name, value: Float(self.visualData[1]))
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorVisual[2].name, value: Float(self.visualData[2]))

                        }
                    }else{
                        if(sensorPayload.temperature != nil && sensorPayload.humidity != nil){
                            self.thermalData[0] = Double(sensorPayload.temperature) - 4.4/// temperature
                            dataToWatch.updateValue(sensorValue: self.thermalData[0], sensorName: "temperatureAmbientData")
                            self.thermalData[1] = Double(sensorPayload.humidity) /// humidity
                            dataToWatch.updateValue(sensorValue: self.thermalData[1], sensorName: "humidityAmbientData")
                            
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueTemp")), sensorName: "minValueTemp")
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueTemp")), sensorName: "maxValueTemp")
                            
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueHum")), sensorName: "minValueHum")
                            dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueHum")), sensorName: "maxValueHum")
                            
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorThermal[0].name, value: Float(self.thermalData[0]))
                            try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorThermal[1].name, value: Float(self.thermalData[1]))

                        }
                    }
                }
                
//                }
                
            case .some(.specPacket(_)):
                break
                
            case .some(.thermPacket(_)):

                var thermNoseTip: Double = 0
                var thermNoseBridge: Double = 0
                var thermTempleFront: Double = 0
                var thermTempleMiddle: Double = 0
                var thermTempleRear: Double = 0
                
//                if let sensorPayload = packet.thermPacket.payload.last{
                for sensorPayload in packet.thermPacket.payload {
                    if(sensorPayload.descriptor == Thermopile_location.tipOfNose){
                        thermNoseTip = Double(sensorPayload.objectTemp)
                    }else if(sensorPayload.descriptor == Thermopile_location.noseBridge){
                        thermNoseBridge = Double(sensorPayload.objectTemp)
                    }else if(sensorPayload.descriptor == Thermopile_location.frontTemple){
                        thermTempleFront = Double(sensorPayload.objectTemp)
                    }else if(sensorPayload.descriptor == Thermopile_location.midTemple){
                        thermTempleMiddle = Double(sensorPayload.objectTemp)
                    }else if(sensorPayload.descriptor == Thermopile_location.rearTemple){
                        thermTempleRear = Double(sensorPayload.objectTemp)
                    }else{
                        
                    }
                }
//                }

                
                /// estimate cog load:  (temple - face)  (high cog load: low face temp -- https://neurosciencenews.com/stress-nasal-temperature-8579/)
                let thermalpileData = thermNoseTip * thermNoseBridge * thermTempleFront * thermTempleMiddle * thermTempleRear
                if (thermalpileData.isInfinite || thermalpileData.isNaN){
//                    #if DEBUG_THERMOPILE
                    print("error parsing thermopile value")
                    print(thermNoseTip)
                    print(thermNoseBridge)
                    print(thermTempleFront)
                    print(thermTempleMiddle)
                    print(thermTempleRear)
//                    #endif
                }else{
                    
//                    print("nose tip \(thermNoseTip)" )
//                    print("nose bridge \(thermNoseBridge)")
//                    print("front \(thermTempleFront)")
//                    print("middle \(thermTempleMiddle)")
//                    print("rear \(thermTempleRear)")
//                    print(packet)
                    if(Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - cogLoadOffset) * cogLoadMultiFactor) > 0){
                        
                        cogIntensity = Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - cogLoadOffset) * cogLoadMultiFactor  + 3)
                        print("cogload baseline: \((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2)")
                        print("cogload est: \(cogIntensity)")
                        dataToWatch.updateValue(sensorValue: Double(cogIntensity), sensorName: "cogLoadData")
                    }else{
                        cogIntensity = 3
                        //                            print("cogload baseline (neg): \((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2)")
                        //                            print("cogload est (neg): \(Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - cogLoadOffset) * cogLoadMultiFactor  + 3))")
                    }
                }
                
            case .some(.imuPacket(_)):
//                print("imu")
                break
            case .some(.micPacket(_)):
//                print(packet)
                break
            case .some(.micLevelPacket(_)):
//                print(packet)
                if let sensorPayload = packet.micLevelPacket.payload.last{
    //                for sensorPayload in packet.micLevelPacket.payload {
                    if(sensorPayload.soundSplDb != nil){
                        self.acoutsticsData[0] = Double(sensorPayload.soundSplDb)
                        dataToWatch.updateValue(sensorValue: self.acoutsticsData[0], sensorName: "noiseData")
                        dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueNoise")), sensorName: "minValueNoise")
                        dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueNoise")), sensorName: "maxValueNoise")
                        try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAcoustics[0].name, value: Float(self.acoutsticsData[0]))

                    }
    //                }
                }

            case .some(.blinkPacket(_)):
//                print(packet)
                break
            case .some(.surveyPacket(_)):
                break
            case .some(.metaDataPacket(_)):
                break
            case .none:
                print("unknown type")
                
            }
        } catch {
            logger.error("packet decode/send problems: \(error).")
            RawDataViewModel.addMetaDataToRawData(payload: "packet decode/send problems: \(error).", timestampUnix: Date(), type: 2)
            
        }
    }
    
    func addDatafromQueueToRawDataDB(){
        DispatchQueue.global().async { [self] in
            let realm = try! Realm()
            rawDataSync.sync {
                print("dequeing")
                let sem = DispatchSemaphore(value: 0)
                while !rawDataQueue.isEmpty {
                    if let data = rawDataQueue.popFirst() {
                        do{
                           
//                            try RawDataViewModel.addRawData(record: data)
                            let rawSensorData = RawSensorData()
                            rawSensorData.binaryRecord = data
                            try! realm.write {
                                realm.add(rawSensorData)
                            }
                            usleep(10000) // add 1/100s         delay
                            sem.signal()
                            sem.wait()
                        }catch{
                            print("cannot add dequed packet to raw data db \(error.localizedDescription)")
                            /// drop these data as it may have bad records
                            rawDataQueue.popFirst()
                            break
                            
                        }
                    }
                }
            }
        }
    }
    
//    func uploadDataFromQueueToServer(){
//        DispatchQueue.global().async { [self] in
//            rawDataSync.sync {
//                print("dequeing")
//                let sem = DispatchSemaphore(value: 0)
//                while !rawDataQueue.isEmpty {
//                    if let data = rawDataQueue.popFirst() {
//                        do{
//                           
//                            try RawDataViewModel.addRawData(record: data)
//                            
//                            
//                            sem.signal()
//                            sem.wait()
//                        }catch{
//                            print("cannot add dequed packet to raw data db \(error.localizedDescription)")
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func realmFetchData(_ n: Int = 10, realm: Realm) throws -> ([SensorPacket], () throws -> Void) {
        if n == 0 {
            return ([], {})
        }

        let results = realm.objects(RawSensorData.self).filter("binaryRecord != nil")
        let limitedResults = Array(results.prefix(n))

        var ret: [SensorPacket] = []
        var err: Error?
        var ids: [ObjectId] = []

        realm.beginWrite()

        limitedResults.forEach { ent in
            ids.append(ent._id)
            if let binaryRecord = ent.binaryRecord {
                do {
                    let sensorPacket = try SensorPacket(serializedData: binaryRecord)
                    ret.append(sensorPacket)
                } catch {
                    var metaData = appMetaDataPacket()
                    metaData.payload = "nil in coredata"
                    metaData.timestampUnix = UInt64(Date().timeIntervalSince1970) * 1000
                    metaData.type = UInt32(2)

                    let sensorPacket = SensorPacket.with {
                        $0.header = SensorPacketHeader.with {
                            $0.epoch = UInt64(NSDate().timeIntervalSince1970 * 1000)
                        }
                        $0.metaDataPacket = metaData
                    }

                    ret.append(sensorPacket)
                }
            }
        }

        do {
            try realm.commitWrite()
        } catch {
            err = error
            print("raw data view model error \(String(describing: err))")
        }

        if let e = err {
            throw e
        }

        return (ret, {
            if ids.isEmpty {
                return
            }

            do {
                realm.beginWrite()

                let objectsToDelete = realm.objects(RawSensorData.self).filter("_id IN %@", ids)
//                realm.delete(objectsToDelete)
                
                // Iterate over the objects to validate and delete them
                for object in objectsToDelete {
                    if object.isInvalidated {
                        
                    }else{
                        // Delete the object from the Realm database
                        realm.delete(object)
                    }
                }

                try realm.commitWrite()
            } catch {
                err = error
                print("raw data view model error \(String(describing: err))")
            }

            if let e = err {
                throw e
            }
        })
    }

    
    func uploadToServer() {
        print("try to upload to server")
        
        /// When using Realm on a background thread, create a serial queue. Realm Database does not support using realms in concurrent queues, such as the global() queue. https://www.mongodb.com/docs/realm/sdk/swift/crud/threading/
        
        
        
        // Pass the reference to a background thread
        DispatchQueue(label: "background", autoreleaseFrequency: .workItem).async {
            let sem = DispatchSemaphore(value: 0)
            let realm = try! Realm()
            
            while true {
                do {
                    /// send the realm data as well
                    let (realmData, realmOnComplete) = try self.realmFetchData(50, realm: realm)
                    if realmData.isEmpty {
                        
                        try realmOnComplete()
                        print("\(Date.now) sent all packets")
                        RawDataViewModel.addMetaDataToRawData(payload: "Sent all packets", timestampUnix: Date(), type: 7)
                        
                        return
                    }
                    
                    var realmErr: Error?
                    
                    try Airspec.send_packets(packets: realmData, auth_token: AUTH_TOKEN) { error in
                        realmErr = error
                        sem.signal()
                    }
                    
                    
                    sem.wait()
                    
                    
                    
                    if let err = realmErr {
                        print("error upload to server")
                        try realmOnComplete()
                        throw err
                    } else {
                        try realmOnComplete()
                    }
                    
                    
                    
                    
                } catch {
                    print("cannot upload the data to the server: \(error)")
                    //                        RawDataViewModel.addMetaDataToRawData(payload: "cannot upload the data to the server: \(error)", timestampUnix: Date(), type: 2)
                    break
                }
                
                /// realm data upload finished
            }
        }

        
        
        
        DispatchQueue.global().async { [self] in
            DispatchQueue.global().sync {
                // https://stackoverflow.com/questions/42772907/what-does-main-sync-in-global-async-mean
                
                
                let sem = DispatchSemaphore(value: 0)
                
                while true {
                    do {
                        /// still upload raw data which comes from meta data
                        let (data, onComplete) = try RawDataViewModel.fetchData()
                        if data.isEmpty {
                            
                            try onComplete()
                            print("\(Date.now) sent all packets")
                            RawDataViewModel.addMetaDataToRawData(payload: "Sent all packets", timestampUnix: Date(), type: 7)
                            
                            return
                        }
                        
                        var err: Error?
                        
                        try Airspec.send_packets(packets: data, auth_token: AUTH_TOKEN) { error in
                            err = error
                            sem.signal()
                        }
                        
                        
                        sem.wait()
                        
                        if let err = err {
                            print("error upload to server")
                            try onComplete()
                            throw err
                        } else {
                            try onComplete()
                        }
                        
                        
                        
                        
                    } catch {
                        print("cannot upload the data to the server: \(error)")
                        //                        RawDataViewModel.addMetaDataToRawData(payload: "cannot upload the data to the server: \(error)", timestampUnix: Date(), type: 2)
                        break
                    }
                }
                
            }
        }
    }
    
    /// check if we shall trigger the LED notification
    func triggerLEDNotification(tempData: [(Date, String, Float)], means: [String: (Float, Date)]){
        var flagcoefficientVariation = false
        var flagcoefficientVariationWho = ""
        var flagcoefficientVariationValue =  0.0
        var flagMean = false
        var flagMeanWho = ""
        var flagMeanValue = 0.0
        var flagRandom = Double.random(in: 0...1) < 0.7 /// 70% chance of being true
        
        logger.info("led notification")
        
        let coefficientVariationBenchmark: Float = 1.0
        
        for (sensorName, (mean, _)) in means {
            
            /// Get the data for the current sensor
            let stringData = tempData.filter { $0.1 == sensorName }.map { $0.2 }
            
            /// Calculate the variance of the sensor data
            let variance = stringData.reduce(0, { $0 + pow($1 - mean, 2) }) / Float(stringData.count)
            let coefficientVariation = sqrt(variance)/mean
            
            
            //            print(coefficientVariation)
            
            /// Check if the variance of the temperature data is above the benchmark
            if coefficientVariation >= coefficientVariationBenchmark {
                /// Trigger LED notification for high variance
                print("Variance for \(sensorName) is above benchmark (\(coefficientVariationBenchmark)): \(coefficientVariation)")
                flagMean = true
                flagcoefficientVariationWho = sensorName
                flagcoefficientVariationValue = Double(coefficientVariation)
                break
            }
            
            /// Check if the mean sensor value is above the benchmark
            if sensorName == SensorIconConstants.sensorThermal[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueTemp"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueTemp"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
            }else if sensorName == SensorIconConstants.sensorThermal[1].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueHum"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueHum"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
                
            }else if sensorName == SensorIconConstants.sensorVisual[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueLightIntensity"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueLightIntensity"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
            }else if sensorName == SensorIconConstants.sensorAcoustics[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueNoise"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueNoise"){
                    flagMean = true
                    flagMeanWho = sensorName
                    flagMeanValue = Double(mean)
                    print("flagMean sensor \(sensorName) and value \(mean)")
                    break
                }
            }else{
                
            }
            
            if( (flagcoefficientVariation || flagMean || flagRandom)){
                let calendar = Calendar.current
                if let prevNotificationTime = UserDefaults.standard.object(forKey: "prevNotificationTime") as? Date{
                    let components = calendar.dateComponents([.minute], from: prevNotificationTime, to: Date())
                    
                    if let minuteDifference = components.minute {
                        if minuteDifference > randomNextNotificationGap {
                            blueGreenLight(isEnable: true)
                            UserDefaults.standard.set(Date(), forKey: "prevNotificationTime")
                            isBlueGreenSurveyDone = false
                            randomNextNotificationGap = Int.random(in: 30...40)
                            notificationTimer = DispatchSource.makeTimerSource()
                            notificationTimer?.schedule(deadline: .now() + .seconds(greenHoldTime + 70), repeating: .never)
                            notificationTimer?.setEventHandler {
                                LocalNotification.setLocalNotification(title: "Did you miss the survey?",
                                                                       subtitle: "",
                                                                       body: "Kindly answer the survey when you notice the LED light is green",
                                                                       when: 1)
                                RawDataViewModel.addMetaDataToRawData(payload: "Survey missing (vibration) triggered", timestampUnix: Date(), type: 3)
                            }
                            notificationTimer?.resume()
                            
                            RawDataViewModel.addMetaDataToRawData(payload: "(LED notification triggered) notification gap: \(randomNextNotificationGap), minuteDifference: \(minuteDifference), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom), flagcoefficientVariationWho: \(flagcoefficientVariationWho), flagcoefficientVariationValue: \(flagcoefficientVariationValue), flagMeanWho: \(flagMeanWho), flagMeanValue: \(flagMeanValue)", timestampUnix: Date(), type: 3)
                        }else{
                            print("(no LED notification)  notification gap: \(randomNextNotificationGap), minuteDifference: \(minuteDifference), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom)")
                            
                            RawDataViewModel.addMetaDataToRawData(payload: "(no LED notification: too short to prev survey) notification gap: \(randomNextNotificationGap), minuteDifference: \(minuteDifference), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom), flagcoefficientVariationWho: \(flagcoefficientVariationWho), flagcoefficientVariationValue: \(flagcoefficientVariationValue), flagMeanWho: \(flagMeanWho), flagMeanValue: \(flagMeanValue)", timestampUnix: Date(), type: 3)
                        }
                    }
                }else{
                    /// first time of notification
                    UserDefaults.standard.set(Date(), forKey: "prevNotificationTime")
                    RawDataViewModel.addMetaDataToRawData(payload: "set initial first notification time reference from bluetoothReceiver", timestampUnix: Date(), type: 3)
                    print("set initial first notification time reference")
                }
                
                
            }else{
                print("(no LED notification)  notification gap: \(randomNextNotificationGap), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom)")
                RawDataViewModel.addMetaDataToRawData(payload: "(no LED notification: not much changes in the environments & random flag decided no)  notification gap: \(randomNextNotificationGap), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom), flagcoefficientVariationWho: \(flagcoefficientVariationWho), flagcoefficientVariationValue: \(flagcoefficientVariationValue), flagMeanWho: \(flagMeanWho), flagMeanValue: \(flagMeanValue)", timestampUnix: Date(), type: 3)
            }
            
        }
        
    }
    
    /// storeLongTermData
    func storeLongTermData() {
        DispatchQueue.global().async {
            DispatchQueue.global().sync {
                self.logger.info("storing long term data")
                
                let sem = DispatchSemaphore(value: 0)
                
                var counter = 0
                while true {
                    do {
                        let (data, onComplete) = try TempDataViewModel.fetchData()
                        if data.isEmpty {
                            print("no new data")
                            if counter == 0{
                                LocalNotification.setLocalNotification(title: "No Sensor data",
                                                                       subtitle: "Please check glasses status",
                                                                       body: "Open AirSpec App on phone, reboot the glasses if needed.",
                                                                       when: 1) /// now
                            }
                            
                            RawDataViewModel.addMetaDataToRawData(payload: "Glasses status check notification (vibration) triggered", timestampUnix: Date(), type: 4)
                            try onComplete()
                            return
                        }
                        
                        var err: Error?
                        
                        /// calculate means (timestamp: Date, sensor: String, value: Float)
                        var sumDict: [String: (Float, Date, Int)] = [:]
                        /// Iterate through the array and update the sum and count for each group
                        data.forEach { item in
                            let key = item.1 /// sensor name
                            let value1 = item.2 /// sensor value
                            let value2 = item.0 /// timestamp
                            if let (sum1, sum2, count) = sumDict[key] {
                                sumDict[key] = (sum1 + value1, value2, count + 1)
                            } else {
                                sumDict[key] = (value1, value2, 1)
                            }
                        }
                        
                        /// Calculate the mean for each group
                        let means = sumDict.mapValues { (sum1, datetime, count) in
                            (sum1 / Float(count), datetime)
                        }
                        
                        var isAllSensorsWorking = true
                        if means.count < 12 {
                            isAllSensorsWorking = false
                        }
                        print(means)
                        ///  means format ["iaq": (61.812943, 1.6771994e+09), "co2": (592.4955, 1.6771994e+09), "noxIndex": (1.0, 1.6771994e+09), "humidity": (17.783474, 1.6771994e+09), "temperature": (27.817734, 1.6771994e+09), "lux": (58.24, 1.677199e+09), "vocIndex": (104.5, 1.6771994e+09)]
                        
                        for (sensor, (mean1, datetime)) in means {
                            let timestamp = datetime
                            let value = mean1
                            // Call your function here with the timestamp, sensor, and value
                            try LongTermDataViewModel.addLongTermData(timestamp: timestamp, sensor: sensor, value: value)
                            if value <= 0 {
                                isAllSensorsWorking = true
                            }
                        }
                        
                        if !isAllSensorsWorking{
                            try RawDataViewModel.addMetaDataToRawData(payload: "Not all sensors are working", timestampUnix: Date(), type: 7)
                            LocalNotification.setLocalNotification(title: "Not all sensors are working",
                                                                   subtitle: "Restart the glasses",
                                                                   body: "Restart the glasses as likely some sensors values are invalid in the past 5 minutes.",
                                                                   when: 1) /// now
                        }

                        try RawDataViewModel.addMetaDataToRawData(payload: "Long term data length: \(LongTermDataViewModel.count()); means: \(means))", timestampUnix: Date(), type: 7)
                        
                        sem.signal()
                        self.triggerLEDNotification(tempData: data, means: means)
                        
                        
                        sem.wait()
                        
                        if let err = err {
                            throw err
                        } else {
                            try onComplete()
                        }
                    } catch {
                        print("cannot push data to the Long Term Data Container: \(error)")
        //                RawDataViewModel.addMetaDataToRawData(payload: "[App issue] cannot push data to the Long Term Data Container: \(error)", timestampUnix: Date(), type: 2)
                    }
                    
                    counter += 1
                }
            }
        }
        
        
    }
    
    
    func blueGreenLight(isEnable: Bool){
        logger.info("blue green: \(isEnable ? "enable" : "disable")")
        
        /// blue green transition
        var blueGreenTransition = AirSpecConfigPacket()
//        if isEnable{
//            blueGreenTransition.header.timestampUnix = timestamp_now()
//        }else{
//            blueGreenTransition.header.timestampUnix = 0
//        }
        //        blueGreenTransition.header.timestampUnix = 0
        
        blueGreenTransition.header.timestampUnix = timestamp_now()
        RawDataViewModel.addMetaDataToRawData(payload: "blueGreenLight: \(blueGreenTransition.header.timestampUnix); isEnabled \(isEnable)", timestampUnix: Date(), type: 2)
        
        blueGreenTransition.blueGreenTransition.enable = isEnable /// true for enable the transition; false for turning off the high sampling rate
        blueGreenTransition.blueGreenTransition.blueMinIntensity = maxIntensity
        blueGreenTransition.blueGreenTransition.blueMaxIntensity = maxIntensity
        blueGreenTransition.blueGreenTransition.greenMaxIntensity = maxIntensity
        blueGreenTransition.blueGreenTransition.stepSize = 1
        blueGreenTransition.blueGreenTransition.stepDurationMs = 6000 /// 53 seconds
        blueGreenTransition.blueGreenTransition.greenHoldLengthSeconds = UInt32(greenHoldTime)
        blueGreenTransition.blueGreenTransition.transitionDelaySeconds = 10
        
        blueGreenTransition.payload = .blueGreenTransition(blueGreenTransition.blueGreenTransition)
        
        do {
            let cmd = try blueGreenTransition.serializedData()
            peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("Fail to send blue-green transition")
            RawDataViewModel.addMetaDataToRawData(payload: "Fail to send blue-green transition: \(error)", timestampUnix: Date(), type: 2)
        }
        
    }
    
    func setBlueInit(){
        logger.info("set blue Init")
        
        /// single LED
        var singleLED = AirSpecConfigPacket()
        singleLED.header.timestampUnix = timestamp_now() /// - 14400000
//        RawDataViewModel.addMetaDataToRawData(payload: "setblueInit: \(singleLED.header.timestampUnix)", timestampUnix: Date(), type: 2)
        
        singleLED.ctrlIndivLed.left.eye.blue = maxIntensity
        singleLED.ctrlIndivLed.left.eye.green = 0
        singleLED.ctrlIndivLed.left.eye.red = 0
        
        singleLED.ctrlIndivLed.right.eye.blue = maxIntensity
        singleLED.ctrlIndivLed.right.eye.green = 0
        singleLED.ctrlIndivLed.right.eye.red = 0
        
        singleLED.payload = .ctrlIndivLed(singleLED.ctrlIndivLed)
        
        do {
            let cmd = try singleLED.serializedData()
            peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("Fail to set blue")
//            RawDataViewModel.addMetaDataToRawData(payload: "Fail to set LED blue: \(error)", timestampUnix: Date(), type: 2)
        }
        
    }
    
    func setBlue(){
        logger.info("set blue")
        /// single LED
        var singleLED = AirSpecConfigPacket()
//        singleLED.header.timestampUnix = 0
        singleLED.header.timestampUnix = timestamp_now() ///- 14400000
        RawDataViewModel.addMetaDataToRawData(payload: "setblue: \(singleLED.header.timestampUnix)", timestampUnix: Date(), type: 2)
        
        singleLED.ctrlIndivLed.left.eye.blue = maxIntensity
        singleLED.ctrlIndivLed.left.eye.green = 0
        singleLED.ctrlIndivLed.left.eye.red = 0
        
        singleLED.ctrlIndivLed.right.eye.blue = maxIntensity
        singleLED.ctrlIndivLed.right.eye.green = 0
        singleLED.ctrlIndivLed.right.eye.red = 0
        
        singleLED.payload = .ctrlIndivLed(singleLED.ctrlIndivLed)
        
        do {
            let cmd = try singleLED.serializedData()
            peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            logger.error("Fail to set blue")
            RawDataViewModel.addMetaDataToRawData(payload: "Fail to set LED blue: \(error)", timestampUnix: Date(), type: 2)
        }
        
    }
    
    
    func dfu(){
        logger.info("dfu")
        
        /// dfu
        var dfu = AirSpecConfigPacket()
        dfu.header.timestampUnix = timestamp_now()
//        dfu.header.timestampUnix = 0
        RawDataViewModel.addMetaDataToRawData(payload: "dfu: \(dfu.header.timestampUnix)", timestampUnix: Date(), type: 2)
        dfu.dfuMode.enable = true
        
        do {
            let cmd = try dfu.serializedData()
            peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            logger.error("fail to set DFU mode")
        }
        
    }
    
    
    func testLight(leftBlue:UInt32, leftGreen:UInt32, leftRed: UInt32, rightBlue: UInt32, rightGreen:UInt32, rightRed:UInt32){
        logger.info("test light")
        /// dfu
        //        var dfu = AirSpecConfigPacket()
        //        dfu.header.timestampUnix = UInt32(Date().timeIntervalSince1970)
        //        dfu.dfuMode.enable = true
        //
        //        do {
        //            let cmd = try dfu.serializedData()
        //            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
        //            print(cmd)
        //        } catch {
        //            //handle error
        //            print("fail to send LED notification")
        //        }
        //
        //
        //        / single LED
        var singleLED = AirSpecConfigPacket()
        //        singleLED.header.timestampUnix = timestamp_now()
        singleLED.header.timestampUnix = 0
        RawDataViewModel.addMetaDataToRawData(payload: "test single LED\(singleLED.header.timestampUnix)", timestampUnix: Date(), type: 2)
        
        singleLED.ctrlIndivLed.left.eye.blue = leftBlue
        singleLED.ctrlIndivLed.left.eye.green = leftGreen
        singleLED.ctrlIndivLed.left.eye.red = leftRed
        
        singleLED.ctrlIndivLed.right.eye.blue = rightBlue
        singleLED.ctrlIndivLed.right.eye.green = rightGreen
        singleLED.ctrlIndivLed.right.eye.red = rightRed
        
        //        singleLED.ctrlIndivLed.left.forward.blue = 50
        //        singleLED.ctrlIndivLed.left.forward.green = 83
        //        singleLED.ctrlIndivLed.left.forward.red = 200
        //
        //        singleLED.ctrlIndivLed.right.forward.blue = 200
        //        singleLED.ctrlIndivLed.right.forward.green = 39
        //        singleLED.ctrlIndivLed.right.forward.red = 50
        //
        //        singleLED.ctrlIndivLed.left.top.blue = 50
        //        singleLED.ctrlIndivLed.left.top.green = 83
        //        singleLED.ctrlIndivLed.left.top.red = 200
        //
        //        singleLED.ctrlIndivLed.right.top.blue = 200
        //        singleLED.ctrlIndivLed.right.top.green = 39
        //        singleLED.ctrlIndivLed.right.top.red = 50
        
        
        singleLED.payload = .ctrlIndivLed(singleLED.ctrlIndivLed)
        
        do {
            let cmd = try singleLED.serializedData()
            peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("fail to send LED notification")
        }
        
        
        
        /// blue green transition
        //        var blueGreenTransition = AirSpecConfigPacket()
        //        blueGreenTransition.header.timestampUnix = UInt64(Date().timeIntervalSince1970 * 1000)
        //
        //        blueGreenTransition.blueGreenTransition.enable = true
        //        blueGreenTransition.blueGreenTransition.blueMinIntensity = 0
        //        blueGreenTransition.blueGreenTransition.blueMaxIntensity = 255
        //        blueGreenTransition.blueGreenTransition.greenMaxIntensity = 255
        //        blueGreenTransition.blueGreenTransition.stepSize = 2
        //        blueGreenTransition.blueGreenTransition.stepDurationMs = 100
        //        blueGreenTransition.blueGreenTransition.greenHoldLengthSeconds = 5
        //        blueGreenTransition.blueGreenTransition.transitionDelaySeconds = 5
        //
        //        blueGreenTransition.payload = .blueGreenTransition(blueGreenTransition.blueGreenTransition)
        //
        //        do {
        //            let cmd = try blueGreenTransition.serializedData()
        //            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
        //            print(cmd)
        //        } catch {
        //            //handle error
        //            print("fail to send LED notification")
        //        }
        
    }
    
    /// older version without the protobuf
    //    func testLight(){
    //        /// https://stackoverflow.com/questions/57985152/how-to-write-a-value-to-characteristc-for-ble-device-in-ios-swift
    //        /// https://stackoverflow.com/questions/57985152/how-to-write-a-value-to-characteristc-for-ble-device-in-ios-swift
    //        /// Bytes are read from right to left, like german language
    ////        var headerBytes: [UInt8] = [0x01, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00] ///  first two byptes: 01 - control LED; byte 3-4: 18 - LED payload size; last 4 bytes: timestamp - to be updated below
    //        /// [packet type byte 0, packet type byte 1, , payload size byte 0, payload size byte 1, unix timestamp, unix timestamp, unix timestamp, unix timestamp] Hex e.g, 18 to be dec and hex is 0x00, 0x12 (we'll see the 0012 as transfered hex value)
    //        ///
    //        //      let payloadBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC8, 0x00, 0x00, 0x00, 0x00, 0xC8, 0x00, 0x00, 0x00, 0x00, 0x00]
    ////        let payloadBytes: [UInt8] = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50] /// all white on
    //
    //
    //        /// Blue-Green Transition mode
    //        var headerBytes: [UInt8] = [0x05, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00]
    //        var payloadBytes: [UInt8] = [0x02, 0x01, 0x32, 0xFF, 0xFF, 0x0A, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    //        let timestamp = Int(Date().timeIntervalSince1970)
    //        let timestampArray = withUnsafeBytes(of: timestamp.bigEndian, Array.init)
    ////        print(timestamp)
    ////        print(timestampArray)
    //        headerBytes[4] = timestampArray[7]
    //        headerBytes[5] = timestampArray[6]
    //        headerBytes[6] = timestampArray[5]
    //        headerBytes[7] = timestampArray[4]
    //
    //        let greenHoldLengthSeconds = Int(30)
    //        let greenHoldLengthSecondsArray = withUnsafeBytes(of: greenHoldLengthSeconds.bigEndian, Array.init)
    //        let transitionDelaySeconds = Int(10)
    //        let transitionDelaySecondsArray = withUnsafeBytes(of: transitionDelaySeconds.bigEndian, Array.init)
    //
    //        payloadBytes[9] = greenHoldLengthSecondsArray[7]
    //        payloadBytes[10] = greenHoldLengthSecondsArray[6]
    //        payloadBytes[11] = greenHoldLengthSecondsArray[5]
    //        payloadBytes[12] = greenHoldLengthSecondsArray[4]
    //
    //        payloadBytes[13] = transitionDelaySecondsArray[7]
    //        payloadBytes[14] = transitionDelaySecondsArray[6]
    //        payloadBytes[15] = transitionDelaySecondsArray[5]
    //        payloadBytes[16] = transitionDelaySecondsArray[4]
    //
    //        print(headerBytes)
    //        /// 18 bytes payload. everyone is up to 255 in decimal -> no need to convert to hex and change the corresponding byte; all 0 is a LED off; 0xFF is fully on
    //        let cmd = Data(headerBytes + payloadBytes)
    //        connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
    ////        return "" /// toggle version
    //    }
    
    func testLightReset(){
        logger.info("test light reset")
        /// https://stackoverflow.com/questions/57985152/how-to-write-a-value-to-characteristc-for-ble-device-in-ios-swift
        /// Bytes are read from right to left, like german language
        var headerBytes: [UInt8] = [0x01, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00]
        let payloadBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] /// all off
        
        /// Blue-Green Transition mode
        //        var headerBytes: [UInt8] = [0x05, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00]
        //        let payloadBytes: [UInt8] = [0x02, 0x01, 0x32, 0xFF, 0xFF, 0x0A, 0x0A]
        
        let timestamp = Int(timestamp_now())
        let timestampArray = withUnsafeBytes(of: timestamp.bigEndian, Array.init)
        
        headerBytes[4] = timestampArray[7]
        headerBytes[5] = timestampArray[6]
        headerBytes[6] = timestampArray[5]
        headerBytes[7] = timestampArray[4]
        print(headerBytes)
        
        let cmd = Data(headerBytes + payloadBytes)
        peripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
    }
}



extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}




