//
//  AirSpec_iOSApp.swift
//  AirSpec_iOS Watch App
//
//  Created by ZHONG Sailin on 20.11.22.
//

import SwiftUI
import UserNotifications

@main
struct AirSpec_iOSApp: App {
    static let name: String = "AirSpec Bluetooth"
    
    init() {
        RawDataViewModel.init_container()
        SurveyDataViewModel.init_container()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(isComfyVote: true, showSurvey: true)
            
        }
    }
}

class InterfaceController: WKInterfaceController {
    func didReceive(_ notification: UNNotification) {
        WKInterfaceDevice.current().play(WKHapticType.notification)
        print("Received notification: \(notification.request.content.body)")
    }
}
