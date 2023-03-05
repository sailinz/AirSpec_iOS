//
//  ContentView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZHONG Sailin on 20.11.22.
//


import SwiftUI
import CoreBluetooth

struct ContentView: View {
//    let viewModel = ProgramViewModel(connectivityProvider: ConnectionProvider())
    @Environment(\.scenePhase) var scenePhase
    @State var isComfyVote: Bool
    @State var showSurvey: Bool
    var body: some View {
        
        WatchHomeView(isComfyVote: $isComfyVote, showSurvey: $showSurvey)
        .onAppear {
            if WKExtension.shared().applicationState == .active {
                // Your app is active and in the foreground
                isComfyVote = true
                print("active")
            }
        }
        .onDisappear {
            if WKExtension.shared().applicationState == .background {
                // Your app has been closed and is running in the background
                isComfyVote = true
                showSurvey = true
                print("go to the background")
            }
        }
        .onChange(of: scenePhase) { newPhase in
            
            if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .active {
                print("Active")
                isComfyVote = true
                showSurvey = true
            } else if newPhase == .background {
                print("Background")
                isComfyVote = true
                showSurvey = true
            }
            
        }
//        SensorReadingView()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var isComfyVote = true
    @State static var isSurvey = true
    static var previews: some View {
        ContentView(isComfyVote: isSurvey, showSurvey: isSurvey)
    }
}
