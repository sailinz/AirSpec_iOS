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
//    static let reachabilityDidChange = Notåification.Name("ReachabilityDidChange")
//}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// Handle WCSession status changes.
//
class SessionDelegator: NSObject, WCSessionDelegate {
    
//    @Published var receivedValue: String?
    let sensorReading: PassthroughSubject<[[Double]], Never>
    let surveyStatus: PassthroughSubject<Bool, Never>
    let eyeCalibrationStatus: PassthroughSubject<Bool, Never>
    var sensorValueNew: [[Double]] = [Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count),
                                      Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count),
                                      Array(repeating: 3, count: 1), /// cog load
                                      SensorIconConstants.sensorThermal.map { $0.minValue }, ///5
                                      SensorIconConstants.sensorThermal.map { $0.maxValue }, ///6
                                      SensorIconConstants.sensorVisual.map { $0.minValue }, /// 7
                                      SensorIconConstants.sensorVisual.map { $0.maxValue }, ///8
                                      SensorIconConstants.sensorAcoustics.map { $0.minValue }, ///9
                                      SensorIconConstants.sensorAcoustics.map { $0.maxValue } ///10
                                      ]
    var isSurveyDone: Bool = false
    var isEyeCalibrationDone: Bool = false
    
    init(sensorReading: PassthroughSubject<[[Double]], Never>, surveyStatus: PassthroughSubject<Bool, Never>, eyeCalibrationStatus: PassthroughSubject<Bool, Never>) {
        self.sensorReading = sensorReading
        self.surveyStatus = surveyStatus
        self.eyeCalibrationStatus = eyeCalibrationStatus
        super.init()
    }
    
    /// Monitor WCSession activation state changes.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    
    /// Did receive an app context.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let sensorReadingValue = applicationContext["temperatureAmbientData"] as? Double {
                self.sensorValueNew[2][1] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["humidityAmbientData"] as? Double {
                self.sensorValueNew[2][2] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["vocIndexAmbientData"] as? Double {
                self.sensorValueNew[1][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["noxIndexAmbientData"] as? Double {
                self.sensorValueNew[1][1] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["co2Data"] as? Double {
                self.sensorValueNew[1][2] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["vocIndexData"] as? Double {
                self.sensorValueNew[1][3] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["noxIndexData"] as? Double {
                self.sensorValueNew[1][4] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["iaqData"] as? Double {
                self.sensorValueNew[1][5] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["luxData"] as? Double {
                self.sensorValueNew[2][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["temperatureData"] as? Double {
                self.sensorValueNew[2][1] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["humidityData"] as? Double {
                self.sensorValueNew[2][2] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["noiseData"] as? Double {
                self.sensorValueNew[3][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["cogLoadData"] as? Double {
                self.sensorValueNew[4][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["minValueTemp"] as? Double {
                self.sensorValueNew[5][0] = sensorReadingValue
                self.sensorValueNew[7][1] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["maxValueTemp"] as? Double {
                self.sensorValueNew[6][0] = sensorReadingValue
                self.sensorValueNew[8][1] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["minValueHum"] as? Double {
                self.sensorValueNew[5][1] = sensorReadingValue
                self.sensorValueNew[7][2] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["maxValueHum"] as? Double {
                self.sensorValueNew[6][1] = sensorReadingValue
                self.sensorValueNew[8][2] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["minValueLightIntensity"] as? Double {
                self.sensorValueNew[7][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["maxValueLightIntensity"] as? Double {
                self.sensorValueNew[8][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["minValueNoise"] as? Double {
                self.sensorValueNew[9][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
            }else if let sensorReadingValue = applicationContext["maxValueNoise"] as? Double {
                self.sensorValueNew[10][0] = sensorReadingValue
                self.sensorReading.send(self.sensorValueNew)
    
            }else {
                print("There was an error")
            }
            
            
        }
        
    }
             
    #if os(iOS)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let isSurveyDone = message["isSurveyDone"] as? Bool {
                self.isSurveyDone = true
                self.surveyStatus.send(isSurveyDone)
//                print("survey status received")
            } else if let isEyeCalibrationDone = message["isEyeCalibrationDone"] as? Bool{
                self.isEyeCalibrationDone = true
                self.eyeCalibrationStatus.send(isEyeCalibrationDone)
            } else {
                print("There was an error")
            }
        }
    }
    #endif
    
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


