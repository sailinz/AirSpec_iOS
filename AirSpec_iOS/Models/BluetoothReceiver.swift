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

    /// -- BLE connection variables
    weak var delegate: BluetoothReceiverDelegate? = nil
    var centralManager: CBCentralManager!
    private var serviceUUID: CBUUID!
    private var TXcharacteristicUUID: CBUUID!
    var sendCharacteristic: CBCharacteristic!
//    let GLASSNAME =  "AirSpec_01ad7855"///"CAPTIVATE"      _01ad6d72
    @Published var GLASSNAME =  ""
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    @Published private(set) var isScanning: Bool = false
    var scanToAlert = false
    var mustDisconnect = false
    @Published var discoveredPeripherals = Set<CBPeripheral>()

    /// -- realtime sensor data
    @Published var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
    @Published var airQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
    @Published var visualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
    @Published var acoutsticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)

    @Published var cogIntensity = 3 /// must scale to a int
    let cogLoadOffset: Double = 3
    let cogLoadMultiFactor: Double = 5

    /// -- watchConnectivity
    @Published var dataToWatch = SensorData()
    var surveyStatusFromWatch = SensorData()
    var isSurveyDone = false
    
    /// -- notification mechenism
    /// maybe the sampling frequency is high enough that the location information is not needed
//    let locationManager = CLLocationManager()
//    var previousLocation: CLLocation?
    var prevNotificationTime: Date = Date()
    var randomNextNotificationGap: Int = 15
    
    
    /// -- push to server
    private var timer: DispatchSourceTimer?
    let updateFrequence = 60 /// seconds
    let batchSize = 50
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
        
        
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now(), repeating: .seconds(updateFrequence))
        timer?.setEventHandler {
            
            self.uploadToServer()
            self.storeLongTermData()
            
            LocalNotification.setLocalNotification(title: "title",
                                                   subtitle: "Subtitle",
                                                   body: "this is body",
                                                   when: 1)
            
        }
        timer?.resume()
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
                
                setBlue() /// set initial blue color and set timestamp to the

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
                
                if(surveyStatusFromWatch.surveyDone){
                    isSurveyDone = true
                    print("received survey status")
                }
                if isSurveyDone{
                    testLight()
                    isSurveyDone = false
                }

                var isIMU = false
                var isMIC = false
                var isBlink = false
                switch packet.payload{
                    case .some(.sgpPacket(_)):
                        print("sgp packet")
//                        print(Date())
//                        print(packet.sgpPacket)
                        for sensorPayload in packet.sgpPacket.payload {
                            if(sensorPayload.vocIndexValue != nil && sensorPayload.noxIndexValue != nil){
                                self.airQualityData[0] = Double(sensorPayload.vocIndexValue) /// voc index
                                dataToWatch.updateValue(sensorValue: self.airQualityData[0], sensorName: "vocIndexData")
                                self.airQualityData[1] = Double(sensorPayload.noxIndexValue) /// nox index
                                dataToWatch.updateValue(sensorValue: self.airQualityData[1], sensorName: "noxIndexData")
                                
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[0].name, value: Float(self.airQualityData[0]))
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[1].name, value: Float(self.airQualityData[1]))
                            }
                        }

                    case .some(.bmePacket(_)):
//                    print(packet.bmePacket)
                        print("bme packet")
                        for sensorPayload in packet.bmePacket.payload {
                            if(sensorPayload.sensorID == BME680_signal_id.co2Eq){
                                self.airQualityData[2] = Double(sensorPayload.signal) /// CO2
                                dataToWatch.updateValue(sensorValue: self.airQualityData[2], sensorName: "co2Data")
                            }else if(sensorPayload.sensorID == BME680_signal_id.iaq){
                                self.airQualityData[3] = Double(sensorPayload.signal) /// IAQ
                                dataToWatch.updateValue(sensorValue: self.airQualityData[3], sensorName: "iaqData")
                                
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[2].name, value: Float(self.airQualityData[2]))
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorAirQuality[3].name, value: Float(self.airQualityData[3]))
                            }
                        }

                    case .some(.luxPacket(_)):
                        print("lux packet")
//                        print(packet.luxPacket)
                        for sensorPayload in packet.luxPacket.payload {
                            if(sensorPayload.lux != nil){
                                self.visualData[0] = Double(sensorPayload.lux) /// lux
                                dataToWatch.updateValue(sensorValue: self.visualData[0], sensorName: "luxData")
                                
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorVisual[0].name, value: Float(self.visualData[0]))
                            }
                        }
                    case .some(.shtPacket(_)):
                        print("sht packet")
//                        print(packet)
                        for sensorPayload in packet.shtPacket.payload {
                            if(sensorPayload.temperature != nil && sensorPayload.humidity != nil){
                                self.thermalData[0] = Double(sensorPayload.temperature) /// temperature
                                dataToWatch.updateValue(sensorValue: self.thermalData[0], sensorName: "temperatureData")
                                print(sensorPayload.humidity)
                                self.thermalData[1] = Double(sensorPayload.humidity) /// humidity
                                dataToWatch.updateValue(sensorValue: self.thermalData[1], sensorName: "humidityData")
                                
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorThermal[0].name, value: Float(self.thermalData[0]))
                                try TempDataViewModel.addTempData(timestamp: Date(), sensor: SensorIconConstants.sensorThermal[1].name, value: Float(self.thermalData[1]))
                            }
                        }
                    case .some(.specPacket(_)):
                        print("spec packet")
                    case .some(.thermPacket(_)):
                    
                        print("thermPacket")
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
                        
                        if(Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - 4) * cogLoadMultiFactor - cogLoadOffset) > 0){
                           
                            cogIntensity = Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - cogLoadOffset) * cogLoadMultiFactor  + 3)
                            print("cogload baseline: \((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2)")
                            print("cogload est: \(cogIntensity)")
                            dataToWatch.updateValue(sensorValue: Double(cogIntensity), sensorName: "cogLoadData")
                        }else{
                            print("cogload baseline (neg): \((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2)")
                            print("cogload est (neg): \(Int(((thermTempleFront + thermTempleMiddle + thermTempleRear)/3 - (thermNoseTip + thermNoseBridge)/2 - cogLoadOffset) * cogLoadMultiFactor  + 3))")
                        }
                        
                        
                    }
                    
                    

                    case .some(.imuPacket(_)):
//                        print("imu packet")
                        isIMU = true
                        break
                    case .some(.micPacket(_)):
//                        print("mic packet")
                        isMIC = true
                    case .some(.blinkPacket(_)):
//                        print("blink packet")
                        isBlink = true
                        break
                    case .some(.surveyPacket(_)):
                        break
                    case .some(.metaDataPacket(_)):
                        break
                    case .none:
                        print("unknown type")

                }
                
                /// this works!
                if(!isMIC && !isIMU && !isBlink){
                    let data = try packet.serializedData()
                    try RawDataViewModel.addRawData(record: data)
                }
                
                
//                reconstructedData.append(packet)
                
//                try Airspec.send_packets(packets: [packet], auth_token: AUTH_TOKEN)

            } catch {
                logger.error("packet decode/send problems: \(error).")
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
                    }
                }
                
            }
        }
    }
    
    /// check if we shall trigger the LED notification
    func triggerLEDNotification(tempData: [(Date, String, Float)], means: [String: (Float, Date)]){
        var flagcoefficientVariation = false
        var flagMean = false
        var flagRandom = Double.random(in: 0...1) < 0.8 /// 80% chance of being true
        
        var meanTriggerSensor: String
        var coeefficientVariationTriggerSensor: String
        
        let coefficientVariationBenchmark: Float = 1.0
        
        for (sensorName, (mean, _)) in means {
            
            /// Get the data for the current sensor
            let stringData = tempData.filter { $0.1 == sensorName }.map { $0.2 }
            
            /// Calculate the variance of the sensor data
            let variance = stringData.reduce(0, { $0 + pow($1 - mean, 2) }) / Float(stringData.count)
            let coefficientVariation = sqrt(variance)/mean
            
            
            print(coefficientVariation)
            
            /// Check if the variance of the temperature data is above the benchmark
            if coefficientVariation >= coefficientVariationBenchmark {
                /// Trigger LED notification for high variance
                print("Variance for \(sensorName) is above benchmark (\(coefficientVariationBenchmark)): \(coefficientVariation)")
                flagMean = true
                break
            }
            
            /// Check if the mean sensor value is above the benchmark
            if sensorName == SensorIconConstants.sensorThermal[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueTemp"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueTemp"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
            }else if sensorName == SensorIconConstants.sensorThermal[1].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueHum"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueHum"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
                
            }else if sensorName == SensorIconConstants.sensorVisual[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueLightIntensity"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueLightIntensity"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
            }else if sensorName == SensorIconConstants.sensorAcoustics[0].name{
                if Double(mean) < UserDefaults.standard.double(forKey: "minValueNoise"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
                
                if Double(mean) > UserDefaults.standard.double(forKey: "maxValueNoise"){
                    flagMean = true
                    print("flagMean sensor \(sensorName) and value \(coefficientVariation)")
                    break
                }
            }else{
                
            }
            
            if( (flagcoefficientVariation || flagMean || flagRandom)){
                let calendar = Calendar.current
                let components = calendar.dateComponents([.minute], from: prevNotificationTime, to: Date())

                if let minuteDifference = components.minute {
                    if minuteDifference > randomNextNotificationGap {
                        print("(led notification) notification gap: \(randomNextNotificationGap), minuteDifference: \(minuteDifference), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom)")
                        testLight()
                        randomNextNotificationGap = Int.random(in: 5...10)
                    }else{
                        print("(no notification)  notification gap: \(randomNextNotificationGap), minuteDifference: \(minuteDifference), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom)")
                    }
                }
            }else{
                print("(no notification)  notification gap: \(randomNextNotificationGap), flagcoefficientVariation: \(flagcoefficientVariation), flagMean: \(flagMean),  flagRandom: \(flagRandom)")
            }
            
            
            
        }

    }

    /// storeLongTermData
    func storeLongTermData() {
                
        while true {
            do {
                let (data, onComplete) = try TempDataViewModel.fetchData()
                if data.isEmpty {
                    print("no new data")
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
                print("long term data length:")
                print(try LongTermDataViewModel.count())
                
                triggerLEDNotification(tempData: data, means: means)

                if let err = err {
                    throw err
                } else {
                    try onComplete()
                }
            } catch {
                print("cannot push data to the Long Term Data Container: \(error)")
            }
        }

    }
    
    
    func blueGreenLight(){

        /// blue green transition
        var blueGreenTransition = AirSpecConfigPacket()
        blueGreenTransition.header.timestampUnix = UInt64(Date().timeIntervalSince1970) * 1000

        blueGreenTransition.blueGreenTransition.enable = true
        blueGreenTransition.blueGreenTransition.blueMinIntensity = 60
        blueGreenTransition.blueGreenTransition.blueMaxIntensity = 60
        blueGreenTransition.blueGreenTransition.greenMaxIntensity = 60
        blueGreenTransition.blueGreenTransition.stepSize = 2
        blueGreenTransition.blueGreenTransition.stepDurationMs = 100
        blueGreenTransition.blueGreenTransition.greenHoldLengthSeconds = 10
        blueGreenTransition.blueGreenTransition.transitionDelaySeconds = 10

        blueGreenTransition.payload = .blueGreenTransition(blueGreenTransition.blueGreenTransition)

        do {
            let cmd = try blueGreenTransition.serializedData()
            connectedPeripheral?.writeValue(cmd, for: sendCharacteristic!, type: .withoutResponse)
            print(cmd)
        } catch {
            //handle error
            print("fail to send LED notification")
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
            print("fail to send LED notification")
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
            print("fail to send LED notification")
        }


        
        

    }


    func testLight(){

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

        singleLED.ctrlIndivLed.left.eye.blue = 200
        singleLED.ctrlIndivLed.left.eye.green = 83
        singleLED.ctrlIndivLed.left.eye.red = 0

        singleLED.ctrlIndivLed.right.eye.blue = 200
        singleLED.ctrlIndivLed.right.eye.green = 83
        singleLED.ctrlIndivLed.right.eye.red = 0

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



