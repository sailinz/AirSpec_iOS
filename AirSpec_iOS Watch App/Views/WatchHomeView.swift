//
//  Home.swift
//  AirSpec_Watch Watch App
//
//  Created by ZHONG Sailin on 03.11.22.
//  developer.apple.com/videos/play/wwdc2021/10005
import SwiftUI
import Foundation
import InfluxDBSwift
import ArgumentParser
import InfluxDBSwiftApis
import Foundation
import UIKit
import WatchKit

struct WatchHomeView: View {
    @Environment(\.scenePhase) var scenePhase
    let AUTH_TOKEN = "4129a31152b56fccfb8b39cab3637706aa5e5f4ded601c45313cd4f7170fc702"

//    let skinTempDataName = ["thermopile_nose_bridge","thermopile_nose_tip","thermopile_temple_back","thermopile_temple_front","thermopile_temple_middle"]
//    @State private var skinTempData = Array(repeating: -1.0, count: 5)
//    var user_id:String = "9067133"
    
//    @State private var cogIntensity = 10 /// must scale to a int
    @StateObject var dataReceivedWatch = SensorData()
    @Binding var isComfyVote: Bool /// is it comfy vote view to be appeared
    @Binding var showSurvey: Bool ///default true
    @Binding var eyeCalibration: Bool
     
    
    var body: some View {
        ZStack{
            ZStack{
                if(!showSurvey || isComfyVote){
                    HeartAnimation(dataReceivedWatch: dataReceivedWatch)
                }
                
                GeometryReader { geometry in
                    ForEach(0..<Int(dataReceivedWatch.sensorValueNew[4][0]), id: \.self) { index in /// cogIntensity
                        let seed = Bool.random()
                        Image("Asset " + String(Int.random(in: 1...18)))
                            .opacity(0.4)
                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                            .scaleEffect(0.3)
                            .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                            .offset(x: self.randomPosition(geometry: geometry, seed: seed).x, y: self.randomPosition(geometry: geometry, seed: seed).y)
                            .shadow(
                                color:Color.pink.opacity(0.5),
                                radius:4)
//                            .animation(Animation.easeIn(duration: 1).delay(1))
                            .animation(Animation.easeIn(duration: 2).delay(2)) ///week 2 experiment
                            
                    }
                }
                
            }.blur(radius: showSurvey ? 10 : 0)
            if(showSurvey){
                WatchSurveyComfyView(eyeCalibration: $eyeCalibration, isComfyVote: $isComfyVote, showSurvey: $showSurvey, surveyStatusToPhone: dataReceivedWatch)
            }
        }
        .onAppear{
            showSurvey = true
            isComfyVote = true
            print("appeared")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                self.uploadToServer()
            }
        }
        
    }
    
    func randomPosition(geometry: GeometryProxy, seed: Bool) -> (x: CGFloat, y:CGFloat){
        let randomRangeX: CGFloat
        if Bool.random() {
            randomRangeX = -20
        } else {
            randomRangeX = geometry.size.width - 30.0
        }
        
        let randomRangeY: CGFloat
        if Bool.random() {
            randomRangeY = -20
        } else {
            randomRangeY = geometry.size.height
        }
        
        
        if seed {
            return (CGFloat.random(in: (0+randomRangeX)...(10+randomRangeX)),CGFloat.random(in: 0...geometry.size.height) )
        }else{
            return (CGFloat.random(in: 0...geometry.size.width), CGFloat.random(in: (0+randomRangeY)...(5+randomRangeY)))
        }
    }
    /// to render the cog load
    func randomX(geometry: GeometryProxy) -> CGFloat {
        // Generate a random x coordinate within the bounds of the view
        let randomRange: CGFloat
        if Bool.random() {
            randomRange = -20
        } else {
            randomRange = geometry.size.width - 30.0
        }
        return CGFloat.random(in: (0+randomRange)...(10+randomRange))
    }

    func randomY(geometry: GeometryProxy) -> CGFloat {
        // Generate a random y coordinate within the bounds of the view
//        let randomRange: CGFloat
//        if Bool.random() {
//            randomRange = 0.0
//        } else {
//            randomRange = geometry.size.height
//        }
//        return CGFloat.random(in: (0+randomRange)...(15+randomRange))
        return CGFloat.random(in: 0...geometry.size.height)

    }
    
    func uploadToServer() {
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                // https://stackoverflow.com/questions/42772907/what-does-main-sync-in-global-async-mean
                
                let sem = DispatchSemaphore(value: 0)
                while true {
                    do {
                        let (data, onComplete) = try RawDataViewModel.fetchData()
                        if data.isEmpty {
                            print("sent all packets")
                            try onComplete()
                            return
                        }
                        
                        var err: Error?
                        
                        try Airspec.send_packets(packets: data, auth_token: AUTH_TOKEN) { error in
                            err = error
                            sem.signal()
                        }
                        
                        sem.wait()

                        if let err = err {
                            throw err
                        } else {
                            try onComplete()
                        }
                    } catch {
                        print("cannot upload the data to the server: \(error)")
                    }
                }
                
            }
        }
    }
    
}




extension Color {
    static func random() -> Color {
        return Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
    }
}

struct WatchHomeView_Previews: PreviewProvider {
    @State static var isComfyVote = true
    @State static var showSurvey = true
    @State static var eyeCalibration = false
    static var previews: some View {
        WatchHomeView(isComfyVote: $isComfyVote, showSurvey: $showSurvey, eyeCalibration: $eyeCalibration)
    }
}






