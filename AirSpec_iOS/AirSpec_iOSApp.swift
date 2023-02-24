//
//  AirSpec_iOSApp.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 20.11.22.
//

import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct AirSpec_iOSApp: App {
//    @Environment(\.scenePhase) private var scenePhase
    static let name: String = "AirSpec Bluetooth"
//    @StateObject var surveyData = SurveyDataViewModel()
//    @StateObject var tempData = TempDataViewModel()
//    @StateObject var metaData = MetaDataViewModel()
    
    init() {
        RawDataViewModel.init_container()
        TempDataViewModel.init_container()
        LongTermDataViewModel.init_container()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environmentObject(surveyData)
//                .environmentObject(tempData)
//                .environmentObject(metaData)
        }
//        .onChange(of: scenePhase) { newPhase in
//            switch newPhase {
//            case .background: scheduleAppRefresh()
//            default: break
//            }
//        }
//        .backgroundTask(.urlSession("RawDataUpload")) {
//            print("intend to upload data")
//        }
    }
    
    /// does not work
//    func scheduleAppRefresh() {
//        let request = BGProcessingTaskRequest(identifier: "RawDataUpload")
//        request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // Schedule the task to start 15 minutes from now
//        do {
//            try BGTaskScheduler.shared.submit(request)
//            print("scheduleAppRefresh scheduled")
//        } catch {
//            print("Could not schedule app refresh: \(error.localizedDescription)")
//        }
//    }
    
}


