//
//  AirSpec_iOSApp.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 20.11.22.
//

import SwiftUI
import UserNotifications
import BackgroundTasks
import WatchConnectivity

@main
struct AirSpec_iOSApp: App {
    static let name: String = "AirSpec Bluetooth"
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State var flags : [Bool] = Array(repeating: false, count: 12)
    
    init() {
        RawDataViewModel.init_container()
//        TempRawDataViewModel.init_container()
        TempDataViewModel.init_container()
        LongTermDataViewModel.init_container()
        SurveyDataViewModel.init_container()
        LocalNotification.init_notification()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(flags: $flags)
        }
    }    
}

///https://prafullkumar77.medium.com/how-to-handle-push-notifications-in-swiftuis-new-app-lifecycle-7532c21d32d7 

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var session: WCSession?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    //No callback in simulator -- must use device to get valid push token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        RawDataViewModel.addMetaDataToRawData(payload: "didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
        print(error.localizedDescription)
    }
}

class NotificationCenter: NSObject, ObservableObject {
    @Published var dumbData: UNNotificationResponse?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
}

extension NotificationCenter: UNUserNotificationCenterDelegate  {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        dumbData = response
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) { }
}

class LocalNotification {
    static func init_notification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (allowed, error) in
            //This callback does not trigger on main loop be careful
            if allowed {
                print("notification allowed")
            } else {
                print("notification error")
                RawDataViewModel.addMetaDataToRawData(payload: "notification error", timestampUnix: Date(), type: 2)
            }
        }
    }
    
    /// thanks to chatgpt :) set identifier to UUID().uuidString rather than identifier: "localNotificatoin"
    static func setLocalNotification(title: String, subtitle: String, body: String, when: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: when, repeats: false)
        let request = UNNotificationRequest.init(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

