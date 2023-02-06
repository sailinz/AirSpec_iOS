//
//  Counter.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.02.23.
//

import Combine
import WatchConnectivity

final class Counter: ObservableObject {
    var session: WCSession
    let delegate: WCSessionDelegate
    let subject = PassthroughSubject<Int, Never>()
    
    @Published private(set) var count: Int = 0
    
    init(session: WCSession = .default) {
        self.delegate = SessionDelegator(sensorReading: subject)
        self.session = session
        self.session.delegate = self.delegate
        self.session.activate()
        
        subject
            .receive(on: DispatchQueue.main)
            .assign(to: &$count)
    }
    
    func updateValue(sensorValue: Int){
        self.count = sensorValue
//        session.sendMessage(["sensorValue": count], replyHandler: nil) { error in
//            print(error.localizedDescription)
//        }
        
        do {
            try session.updateApplicationContext(["sensorValue": count])
        } catch {
            print(error.localizedDescription)
        }
        
        
    }
}
