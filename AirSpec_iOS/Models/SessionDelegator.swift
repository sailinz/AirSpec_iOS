/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the WCSessionDelegate methods.
https://developer.apple.com/documentation/watchconnectivity/implementing_two-way_communication_using_watch_connectivity
*/

import Foundation
import WatchConnectivity
import Combine

#if os(watchOS)
import ClockKit
#endif

// Custom notifications happen when Watch Connectivity activation or reachability status changes,
// or when receiving or sending data. Clients observe these notifications to update the UI.
//
//extension Notification.Name {
//    static let dataDidFlow = Notification.Name("DataDidFlow")
//    static let activationDidComplete = Notification.Name("ActivationDidComplete")
//    static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
//}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// Handle WCSession status changes.
//
class SessionDelegator: NSObject, WCSessionDelegate {
    
//    @Published var receivedValue: String?
    let sensorReading: PassthroughSubject<Int, Never>
    
    init(sensorReading: PassthroughSubject<Int, Never>) {
        self.sensorReading = sensorReading
        super.init()
    }
    
    /// Monitor WCSession activation state changes.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    
    /// Did receive an app context.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
//        guard let value = applicationContext["sensorValue"] as? String else { return }
//                receivedValue = value
        DispatchQueue.main.async {
            if let temp = applicationContext["sensorValue"] as? Int {
                self.sensorReading.send(temp)
            } else {
                print("There was an error")
            }
        }
        
    }
    
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let temp = message["sensorValue"] as? Int {
                self.sensorReading.send(temp)
            } else {
                print("There was an error")
            }
        }
    }
    
    /// WCSessionDelegate methods for iOS only.
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        /// Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
    
}

