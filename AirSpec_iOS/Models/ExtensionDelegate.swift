/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The delegate manages the app's life cycle and handles background refresh tasks.
*/


import CoreBluetooth
import os.log
import BackgroundTasks
import UIKit


class ExtensionDelegate: NSObject, UIApplicationDelegate, BluetoothReceiverDelegate {
    
    private let logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: ExtensionDelegate.self)
    )
    
    private var currentRefreshTask: BGAppRefreshTask?
    
    static private(set) var instance: ExtensionDelegate! = nil
    private(set) var bluetoothReceiver: BluetoothReceiver!
//    private(set) var notificationHandler: NotificationHandler!

    override init() {
        super.init()
        
        ExtensionDelegate.instance = self

//        notificationHandler = NotificationHandler()

        bluetoothReceiver = BluetoothReceiver(
            service: BluetoothConstants.airspecServiceUUID,
            characteristic: BluetoothConstants.airspecTXCharacteristicUUID
        )
        bluetoothReceiver.delegate = self
    }
    
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
////        print("Your code here")
//        return true
//    }
    
    func handle(_ backgroundTasks: Set<BGAppRefreshTask>) {
        
//        for task in backgroundTasks {
//            switch task {
//            case let refreshTask as WKApplicationRefreshBackgroundTask:
//
//                logger.info("handling background app refresh task")
//
//                /// Check to see whether you disconnected from any peripherals. If not, end the background refresh task.
//                guard let peripheral = bluetoothReceiver.knownDisconnectedPeripheral, shouldReconnect(to: peripheral) else {
//                    logger.info("no known disconnected peripheral to reconnect to")
//                    completeRefreshTask(refreshTask)
//                    return
//                }
//
//                /// Reconnect to the known disconnected Bluetooth peripheral and read its characteristic value.
//                bluetoothReceiver.connect(to: peripheral)
//
//                refreshTask.expirationHandler = {
//                    self.logger.info("background runtime is about to expire")
//
////                    if #unavailable(watchOS 9.0) {
//                        /// When the background refresh task is about to expire, disconnect from the peripheral if you haven't done so already.
//                    if let peripheral = self.bluetoothReceiver.connectedPeripheral {
//                        self.bluetoothReceiver.disconnect(from: peripheral, mustDisconnect: false)
//                    }
////                    }
//                }
//
//                currentRefreshTask = refreshTask
//
//            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
//                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: .distantFuture, userInfo: nil)
//            default:
//                task.setTaskCompletedWithSnapshot(false)
//            }
//        }
    }
    
    private func shouldReconnect(to peripheral: CBPeripheral) -> Bool {
        /// Implement your own logic to determine whether the peripheral needs to reconnect.
        return true
    }
    
    private func completeRefreshTask(_ task: BGAppRefreshTask) {
        logger.info("setting background app refresh task as complete")
//        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: BluetoothReceiverDelegate
    
    func didCompleteDisconnection(from peripheral: CBPeripheral, mustDisconnect: Bool) {
        /// If the peripheral completes its disconnection and you're handling a background refresh task, complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        } else {
            if !mustDisconnect && bluetoothReceiver.knownDisconnectedPeripheral != nil {
                bluetoothReceiver.connect(to: bluetoothReceiver.knownDisconnectedPeripheral!)
            }
            /// Clear the complication value to demonstrate disconnect/reconnect actions.
            UserDefaults.standard.setValue(-1, forKey: BluetoothConstants.receivedDataKey)
//                ComplicationController.updateAllActiveComplications()
        }
    }
    
    func didFailWithError(_ error: BluetoothReceiverError) {
        /// If the `BluetoothReceiver` fails and you're handling a background refresh task, complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        }
    }
    
    func didReceiveData(_ data: Data) -> Int {
//        guard let value = try? JSONDecoder().decode(Int.self, from: data) else {
//            logger.error("failed to decode float from data")
//            return -1
//        }
        
        logger.info("received value from peripheral") //: \(value)
//        UserDefaults.standard.setValue(value, forKey: BluetoothConstants.receivedDataKey)
        
//        ComplicationController.updateAllActiveComplications()
        
        /// When you're handling a background refresh task and are done interacting with the peripheral,
        /// disconnect from it as soon as possible if not in watchOS 9 or later.
        /// watchOS 9 adds the capability to continue scanning and to maintain connections in the background.
//        if #unavailable(watchOS 9.0) {
        if currentRefreshTask != nil, let peripheral = bluetoothReceiver.connectedPeripheral {
            bluetoothReceiver.disconnect(from: peripheral, mustDisconnect: true)
        }
//        }
        
//        return value
        return 2
    }
}


