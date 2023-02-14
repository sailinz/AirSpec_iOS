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
    let subject = PassthroughSubject<[[Double]], Never>()

    @Published private(set) var sensorValueNew: [[Double]] = [Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count),
                                                              Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count),
                                                              Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count),
                                                              Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count),
                                                              Array(repeating: 3, count: 1)  ] /// cog load
    

    init(session: WCSession = .default) {
        self.delegate = SessionDelegator(sensorReading: subject)
        self.session = session
        self.session.delegate = self.delegate
        self.session.activate()

        subject
            .receive(on: DispatchQueue.main)
            .assign(to: &$sensorValueNew)
    }

    func updateValue(sensorValue: Double, sensorName: String){
        do {
            try session.updateApplicationContext([sensorName: sensorValue])
        } catch {
            print(error.localizedDescription)
        }
    }
}

