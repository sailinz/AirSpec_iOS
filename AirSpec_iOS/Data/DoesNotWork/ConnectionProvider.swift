//
//  ConnectionProvider.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.02.23.
//

/// for watch connectivity
import Foundation
import WatchConnectivity

class ConnectionProvider: NSObject, WCSessionDelegate{
    private let session: WCSession
    var programs : ProgramObject?
    var receivedPrograms: ProgramObject?
    
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        #if os(iOS)
            print("Connection provider initialized on phone")
        #endif
        
        #if os(watchOS)
            print("Connection provider initialized on watch")
        #endif
        
        self.connect()
    }
    
    func connect(){
        guard WCSession.isSupported()
        else{
            print("WCSession is not supported")
            return
        }
    }
    
    func send(message: [String : Any]) -> Void{
        do {
            try WCSession.default.updateApplicationContext(message)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        if(message["progData"] != nil){
            let loadedData = message["progData"]
            
            NSKeyedUnarchiver.setClass(ProgramObject.self, forClassName: "ProgramObject")
            
            let loadedSensorData = try! NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: ProgramObject.self, from: loadedData as! Data) as? ProgramObject
            
            self.receivedPrograms = loadedSensorData!
            print("sensor data received")
        }
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
    
    
}
