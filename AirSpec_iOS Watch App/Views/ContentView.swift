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
    @State var user_id:String = ""
    @State var eyeCalibration:Bool
    
    var body: some View {
        if let user_id = UserDefaults.standard.string(forKey: "user_id"){
            if user_id != ""{
                WatchHomeView(isComfyVote: $isComfyVote, showSurvey: $showSurvey, eyeCalibration: $eyeCalibration)
                .onAppear {
                    if WKExtension.shared().applicationState == .active {
                        // Your app is active and in the foreground
                        isComfyVote = true
                        eyeCalibration = false
                        print("active")
                        print(UserDefaults.standard.string(forKey: "user_id"))
                    }
                }
                .onDisappear {
                    if WKExtension.shared().applicationState == .background {
                        // Your app has been closed and is running in the background
                        isComfyVote = true
                        showSurvey = true
                        eyeCalibration = false
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
                        eyeCalibration = false
                    } else if newPhase == .background {
                        print("Background")
                        isComfyVote = true
                        showSurvey = true
                        eyeCalibration = false
                    }
                    
                }
            }else{
                TextField("Enter ID", text: $user_id, onCommit: {
                    UserDefaults.standard.set(self.user_id, forKey: "user_id")
                })
                .multilineTextAlignment(.trailing)
                .font(.system(.subheadline))
            }
            
        }else{
            TextField("Enter ID", text: $user_id, onCommit: {
                UserDefaults.standard.set(self.user_id, forKey: "user_id")
            })
            .multilineTextAlignment(.trailing)
            .font(.system(.subheadline))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var isComfyVote = true
    @State static var isSurvey = true
    @State static var eyeCalibration = false
    static var previews: some View {
        ContentView(isComfyVote: isSurvey, showSurvey: isSurvey, eyeCalibration: eyeCalibration)
    }
}
