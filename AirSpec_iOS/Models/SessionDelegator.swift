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
    let sensorReading: PassthroughSubject<[[Double]], Never>
    var sensorValueNew: [[Double]] = [Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count),
                                      Array(repeating: 3, count: 1)  ] /// cog load
    
    init(sensorReading: PassthroughSubject<[[Double]], Never>) {
        self.sensorReading = sensorReading
        super.init()
    }
    
    /// Monitor WCSession activation state changes.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    
    /// Did receive an app context.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let sensorReadingValue = applicationContext["temperatureData"] as? Double {
                self.sensorValueNew[0][0] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["humidityData"] as? Double {
                self.sensorValueNew[0][1] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["vocIndexData"] as? Double {
                self.sensorValueNew[1][0] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["noxIndexData"] as? Double {
                self.sensorValueNew[1][1] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["co2Data"] as? Double {
                self.sensorValueNew[1][2] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["iaqData"] as? Double {
                self.sensorValueNew[1][3] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["luxData"] as? Double {
                self.sensorValueNew[2][0] = sensorReadingValue
            }else if let sensorReadingValue = applicationContext["cogLoadData"] as? Double {
                self.sensorValueNew[4][0] = sensorReadingValue
            } else {
                print("There was an error")
            }
            
            self.sensorReading.send(self.sensorValueNew)
        }
        
    }
    
    
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        DispatchQueue.main.async {
//            if let temp = message["sensorValue"] as? Int {
//                self.sensorReading.send(temp)
//            } else {
//                print("There was an error")
//            }
//        }
//    }
    
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

