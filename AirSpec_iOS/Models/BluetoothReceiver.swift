//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin and Nathan PERRY on 14.02.23.

import CoreBluetooth
import os.log
import CoreData
import CoreLocation

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

let AUTH_TOKEN = "4129a31152b56fccfb8b39cab3637706aa5e5f4ded601c45313cd4f7170fc702"

/// A listener to subscribe to a Bluetooth LE peripheral and get characteristic updates the data to a TCP server.
///
class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: BluetoothReceiver.self)
    )


    /// -- BLE CONNNECTION VARIABLES
    weak var delegate: BluetoothReceiverDelegate? = nil
    var centralManager: CBCentralManager!
    private var serviceUUID: CBUUID!
    private var TXcharacteristicUUID: CBUUID!
    var sendCharacteristic: CBCharacteristic!
    @Published var GLASSNAME =  ""
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var isFound: Bool = false
    var scanToAlert = false
    var mustDisconnect = false
    @Published var discoveredPeripherals = Set<CBPeripheral>()

    /// -- REAL-TIME SENSOR DATA
    @Published var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
    @Published var airQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
    @Published var visualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
    @Published var acoutsticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)

    @Published var cogIntensity = 3 /// must scale to a int
    let cogLoadOffset: Double = 2
    let cogLoadMultiFactor: Double = 5

    /// -- WATCH CONNECTIVITY
    @Published var dataToWatch = SensorData()
    @Published var isBlueGreenSurveyDone = false
    //    var surveyStatusFromWatch = SensorData()
    
    /// -- NOTIFICATION MECHENISM
    /// maybe the sampling frequency is high enough that the location information is not needed
//    let locationManager = CLLocationManager()
//    var previousLocation: CLLocation?
//    var prevNotificationTime: Date = Date().addingTimeInterval(-60*60)
    var randomNextNotificationGap: Int = 40 /// minute
    var notificationTimer:DispatchSourceTimer?
    @Published var greenHoldTime = 60 * 15 /// sec
    var disconnectionTimer:DispatchSourceTimer?
    
    /// -- PUSH TO THE SERVER
    private var timer: DispatchSourceTimer?
    let updateFrequence = 60 * 6 /// seconds
//    let batchSize = 50
//    private var reconstructedData:[SensorPacket] = [] /// for testing only

    
    
    init(service: CBUUID, characteristic: CBUUID) {
        
        super.init()
        self.serviceUUID = service
        self.TXcharacteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        let user_id_int = Int(UserDefaults.standard.string(forKey: "user_id") ?? "") ?? 0
        if( user_id_int != 0){
            self.GLASSNAME = BluetoothConstants.glassesNames[user_id_int]
            print("glass name (init): \(GLASSNAME)")
        }
    
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
            isFound = true
//            print("device: \(discoveredPeripherals)")
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
        
        isFound = true
        RawDataViewModel.addMetaDataToRawData(payload: "connected to \(peripheral.name ?? "unnamed peripheral")", timestampUnix: Date(), type: 5)
        disconnectionTimer?.cancel()
        disconnectionTimer = nil

        
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now() + .seconds(60), repeating: .seconds(updateFrequence))
        timer?.setEventHandler {
            self.uploadToServer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 90)  { /// wait for 3 sec
                self.storeLongTermData()
            }
            
        }
        timer?.resume()
    }

    /// If the app wakes up to handle a background refresh task, the system calls this method if
    /// a peripheral disconnects when the app transitions to the background.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("disconnected from \(peripheral.name ?? "unnamed peripheral")")
        connectedPeripheral = nil
        isFound = false
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
        
        
        

        /// Keep track of the last known peripheral.
        knownDisconnectedPeripheral = peripheral

        delegate?.didCompleteDisconnection(from: peripheral, mustDisconnect: self.mustDisconnect)
        self.mustDisconnect = false
        
        /// stop data stream to the server
        timer?.cancel()
        timer = nil
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

                /// set initial blue color and set timestamp to the latest
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3)  { /// wait for 3 sec
                    self.setBlue()
                }

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
                    RawDataViewModel.addMetaDataToRawData(payload: "failed parsing packet: \(error) ", timestampUnix: Date(), type: 2)
                    return
                }
//                print(packet)
                
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
//                    blueGreenLight(isEnable: false)
                    setBlue()
//                    testLight(leftBlue: 150, leftGreen: 20, leftRed: 0, rightBlue: 150, rightGreen: 20, rightRed: 0)
                    dataToWatch.isEyeCalibrationDone = false
                    RawDataViewModel.addMetaDataToRawData(payload: "eye calibration started", timestampUnix: Date(), type: 2)
                }

                

                switch packet.payload{
                    case .some(.sgpPacket(_)):
                        for sensorPayload in packet.sgpPacket.payload {
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

                    case .some(.bmePacket(_)):
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
                        for sensorPayload in packet.luxPacket.payload {
                            if(sensorPayload.lux != nil){
                                self.visualData[0] = Double(sensorPayload.lux) /// lux
                                dataToWatch.updateValue(sensorValue: self.visualData[0], sensorName: "luxData")
                                dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueLightIntensity")), sensorName: "minValueLightIntensity")
                                dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueLightIntensity")), sensorName: "maxValueLightIntensity")
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorVisual[0].name, value: Float(self.visualData[0]))
                            }
                        }
                    case .some(.shtPacket(_)):
                        for sensorPayload in packet.shtPacket.payload {
                            if packet.shtPacket.sensorID == 0 {
                                if(sensorPayload.temperature != nil && sensorPayload.humidity != nil){
                                    self.visualData[1] = Double(sensorPayload.temperature) /// temperature
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
                                    self.thermalData[0] = Double(sensorPayload.temperature) /// temperature
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
                    case .some(.specPacket(_)):
                        break
                    case .some(.thermPacket(_)):
                        var thermNoseTip: Double = 0
                        var thermNoseBridge: Double = 0
                        var thermTempleFront: Double = 0
                        var thermTempleMiddle: Double = 0
                        var thermTempleRear: Double = 0

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

                    /// estimate cog load:  (temple - face)  (high cog load: low face temp -- https://neurosciencenews.com/stress-nasal-temperature-8579/)
                    let thermalpileData = thermNoseTip * thermNoseBridge * thermTempleFront * thermTempleMiddle * thermTempleRear
                    if (thermalpileData.isInfinite || thermalpileData.isNaN){
                        print("error parsing thermopile value")
                        print(thermNoseTip)
                        print(thermNoseBridge)
                        print(thermTempleFront)
                        print(thermTempleMiddle)
                        print(thermTempleRear)
                    }else{
                        
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
                        break
                    case .some(.micPacket(_)):
                        print("mic")
                        print(packet)
                        break
                    case .some(.micLevelPacket(_)):
                        print("micLevelPacket")
                        print(packet)
                        for sensorPayload in packet.micLevelPacket.payload {
                            if(sensorPayload.soundSplDb != nil){
                                self.acoutsticsData[0] = Double(sensorPayload.soundSplDb)
                                dataToWatch.updateValue(sensorValue: self.acoutsticsData[0], sensorName: "noiseData")
                                dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "minValueNoise")), sensorName: "minValueNoise")
                                dataToWatch.updateValue(sensorValue: Double(UserDefaults.standard.float(forKey: "maxValueNoise")), sensorName: "maxValueNoise")

                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAcoustics[0].name, value: Float(self.acoutsticsData[0]))
                            }
                        }
                    
                    case .some(.blinkPacket(_)):
                        print("blink packet")
//                        isBlink = true
                        break
                    case .some(.surveyPacket(_)):
                        break
                    case .some(.metaDataPacket(_)):
                        break
                    case .none:
                        print("unknown type")

                }
                
                
                let data = try packet.serializedData()
                try RawDataViewModel.addRawData(record: data)
                
                

            } catch {
                logger.error("packet decode/send problems: \(error).")
                RawDataViewModel.addMetaDataToRawData(payload: "packet decode/send problems: \(error).", timestampUnix: Date(), type: 2)

            }

        }
    }
    
    
    
    func uploadToServer() {
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                // https://stackoverflow.com/questions/42772907/what-does-main-sync-in-global-async-mean
                
                let sem = DispatchSemaphore(value: 0)
                while true {
                    do {
                        let (data, onComplete) = try RawDataViewModel.fetchData()
                        if data.isEmpty {
                            print("sent all packets")
                            RawDataViewModel.addMetaDataToRawData(payload: "Sent all packets", timestampUnix: Date(), type: 7)
                            try onComplete()
                            return
                        }
                        
                        var err: Error?
                        
                        try Airspec.send_packets(packets: data, auth_token: AUTH_TOKEN) { error in
                            err = error
                            sem.signal()
                        }
                        
                        sem.wait()

                        if let err = err {
                            throw err
                        } else {
                            try onComplete()
                        }
                    } catch {
                        print("cannot upload the data to the server: \(error)")
                        RawDataViewModel.addMetaDataToRawData(payload: "cannot upload the data to the server: \(error)", timestampUnix: Date(), type: 2)

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
                            randomNextNotificationGap = Int.random(in: 15...20              )
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

                print(means)
                ///  means format ["iaq": (61.812943, 1.6771994e+09), "co2": (592.4955, 1.6771994e+09), "noxIndex": (1.0, 1.6771994e+09), "humidity": (17.783474, 1.6771994e+09), "temperature": (27.817734, 1.6771994e+09), "lux": (58.24, 1.677199e+09), "vocIndex": (104.5, 1.6771994e+09)]
                
                for (sensor, (mean1, datetime)) in means {
                    let timestamp = datetime
                    let value = mean1
                    // Call your function here with the timestamp, sensor, and value
                    try LongTermDataViewModel.addLongTermData(timestamp: timestamp, sensor: sensor, value: value)
                    
                }
//                print("long term data length:")
//                print(try LongTermDataViewModel.count())
                try RawDataViewModel.addMetaDataToRawData(payload: "Long term data length: \(LongTermDataViewModel.count())", timestampUnix: Date(), type: 7)
                
                
                triggerLEDNotification(tempData: data, means: means)
                notificationTimer = DispatchSource.makeTimerSource()
                notificationTimer?.schedule(deadline: .now() + .seconds(greenHoldTime), repeating: .never)
                notificationTimer?.setEventHandler {
                    LocalNotification.setLocalNotification(title: "Did you miss the survey?",
                                                           subtitle: "",
                                                           body: "Kindly answer the survey when you notice the LED light is green",
                                                           when: 1)
                    RawDataViewModel.addMetaDataToRawData(payload: "Survey missing (vibration) triggered", timestampUnix: Date(), type: 3)
                }
                notificationTimer?.resume()

                if let err = err {
                    throw err
                } else {
                    try onComplete()
                }
            } catch {
                print("cannot push data to the Long Term Data Container: \(error)")
                RawDataViewModel.addMetaDataToRawData(payload: "[App issue] cannot push data to the Long Term Data Container: \(error)", timestampUnix: Date(), type: 2)
            }
            
            counter += 1
        }

    }
    
    
    func blueGreenLight(isEnable: Bool){

        /// blue green transition
        var blueGreenTransition = AirSpecConfigPacket()
        blueGreenTransition.header.timestampUnix = UInt64(Date().timeIntervalSince1970) * 1000

        blueGreenTransition.blueGreenTransition.enable = isEnable /// true for enable the transition; false for turning off the high sampling rate
        blueGreenTransition.blueGreenTransition.blueMinIntensity = 60
        blueGreenTransition.blueGreenTransition.blueMaxIntensity = 60
        blueGreenTransition.blueGreenTransition.greenMaxIntensity = 60
        blueGreenTransition.blueGreenTransition.stepSize = 2
        blueGreenTransition.blueGreenTransition.stepDurationMs = 200
        blueGreenTransition.blueGreenTransition.greenHoldLengthSeconds = UInt32(greenHoldTime)
        blueGreenTransition.blueGreenTransition.transitionDelaySeconds = 10

        blueGreenTransition.payload = .blueGreenTransition(blueGreenTransition.blueGreenTransition)

        do {
            let cmd = try blueGreenTransition.serializedData()
            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("Fail to send blue-green transition")
            RawDataViewModel.addMetaDataToRawData(payload: "Fail to send blue-green transition: \(error)", timestampUnix: Date(), type: 2)
        }

    }
    
    func setBlue(){

        print("set blue")
        /// single LED
        var singleLED = AirSpecConfigPacket()
        singleLED.header.timestampUnix = UInt64(Date().timeIntervalSince1970) * 1000

        singleLED.ctrlIndivLed.left.eye.blue = 60
        singleLED.ctrlIndivLed.left.eye.green = 0
        singleLED.ctrlIndivLed.left.eye.red = 0

        singleLED.ctrlIndivLed.right.eye.blue = 60
        singleLED.ctrlIndivLed.right.eye.green = 0
        singleLED.ctrlIndivLed.right.eye.red = 0

        singleLED.payload = .ctrlIndivLed(singleLED.ctrlIndivLed)

        do {
            let cmd = try singleLED.serializedData()
            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("Fail to set blue")
            RawDataViewModel.addMetaDataToRawData(payload: "Fail to set LED blue: \(error)", timestampUnix: Date(), type: 2)
        }

    }
    
    
    func dfu(){

        /// dfu
        var dfu = AirSpecConfigPacket()
        dfu.header.timestampUnix = UInt64(Date().timeIntervalSince1970)
        dfu.dfuMode.enable = true

        do {
            let cmd = try dfu.serializedData()
            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("fail to set DFU mode")
        }

    }


    func testLight(leftBlue:UInt32, leftGreen:UInt32, leftRed: UInt32, rightBlue: UInt32, rightGreen:UInt32, rightRed:UInt32){

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
        singleLED.header.timestampUnix = UInt64(Date().timeIntervalSince1970)

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
            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("fail to send LED notification")
        }



        /// blue green transition
//        var blueGreenTransition = AirSpecConfigPacket()
//        blueGreenTransition.header.timestampUnix = UInt64(Date().timeIntervalSince1970) * 1000
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




