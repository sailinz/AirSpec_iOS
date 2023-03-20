/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The delegate manages the app's life cycle and handles background refresh tasks.
*/


import CoreBluetooth
import os.log
import BackgroundTasks
import UIKit

class ExtensionDelegate: NSObject, UIApplicationDelegate {
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

        bluetoothReceiver = BluetoothReceiver()
        setBtFromUserDefaults(bluetoothReceiver)
    }
    
//    func handle(_ backgroundTasks: Set<BGAppRefreshTask>) {
        
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
//    }
    
    private func shouldReconnect(to peripheral: CBPeripheral) -> Bool {
        /// Implement your own logic to determine whether the peripheral needs to reconnect.
        return true
    }
    
    private func completeRefreshTask(_ task: BGAppRefreshTask) {
        logger.info("setting background app refresh task as complete")
//        task.setTaskCompletedWithSnapshot(false)
    }
}
