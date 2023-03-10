//
//  Counter.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.02.23.
// https://cgaaf.medium.com/swiftui-watch-connectivity-in-4-steps-594f90f3a0bc

import Combine
import WatchConnectivity

final class SensorData: ObservableObject {
    var session: WCSession
    let delegate: WCSessionDelegate
    
    
    let sensorReading = PassthroughSubject<[[Double]], Never>()
    @Published private(set) var sensorValueNew: [[Double]] = [
      Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count), ///0
      Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count), ///1
      Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count), ///2
      Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count), ///3
      Array(repeating: 3, count: 1), /// cog load 4
      SensorIconConstants.sensorThermal.map { $0.minValue }, ///5
      SensorIconConstants.sensorThermal.map { $0.maxValue }, ///6
      SensorIconConstants.sensorVisual.map { $0.minValue }, /// 7
      SensorIconConstants.sensorVisual.map { $0.maxValue }, ///8
      SensorIconConstants.sensorAcoustics.map { $0.minValue }, ///9
      SensorIconConstants.sensorAcoustics.map { $0.maxValue } ///10
                                                              
    ]
    
    
    
    let surveyStatus = PassthroughSubject<Bool, Never>()
    @Published var surveyDone: Bool = false
    
    
    init(session: WCSession = .default) {
        self.delegate = SessionDelegator(sensorReading: sensorReading, surveyStatus:surveyStatus)
        self.session = session
        self.session.delegate = self.delegate
        self.session.activate()
        sensorReading
            .receive(on: DispatchQueue.main)
            .assign(to: &$sensorValueNew)
        
        surveyStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$surveyDone)
        
    }

    
    func updateValue(sensorValue: Double, sensorName: String){
        do {
            try session.updateApplicationContext([sensorName: sensorValue])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func updateSurveyStatus(isSurveyDone: Bool){
//        do {
//            try session.updateApplicationContext(["isSurveyDone": isSurveyDone])
//        } catch {
//            print(error.localizedDescription)
//        }
        session.sendMessage(["isSurveyDone": isSurveyDone], replyHandler: nil) { error in
                    print(error.localizedDescription)
                }
    }

}

