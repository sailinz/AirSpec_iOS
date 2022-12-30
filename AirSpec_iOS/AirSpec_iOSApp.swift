//
//  AirSpec_iOSApp.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 20.11.22.
//

import SwiftUI
import UserNotifications

@main
struct AirSpec_iOSApp: App {
//    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    static let name: String = "AirSpec Bluetooth"
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


//class AppDelegate: NSObject, UIApplicationDelegate {
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//            // This method is called whenever a push notification is received by the device
//
//            // Trigger the function that you want to run when the push notification is received
//            handlePushNotification(userInfo)
//        }
//    
//    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
//            // This is the function that will be triggered when a push notification is received
//            // You can use the userInfo dictionary to access the data included in the push notification payload
//        }
//
//
//}
