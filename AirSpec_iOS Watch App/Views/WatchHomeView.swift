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
//    @State private var isActive = false
    
    let influxClient = try InfluxDBClient(url: NetworkConstants.url, token: NetworkConstants.token)
    
    @State private var timer: DispatchSourceTimer?
    let skinTempDataName = ["thermopile_nose_bridge","thermopile_nose_tip","thermopile_temple_back","thermopile_temple_front","thermopile_temple_middle"]
    @State private var skinTempData = Array(repeating: -1.0, count: 5)
    var user_id:String = "9067133"
    
    @State private var cogIntensity = 10 /// must scale to a int
    let updateFrequence = 10 /// seconds
    
    @State private var isSurvey = true
//    let application = UIApplication.shared
    @Environment(\.openURL) private var openURL
    let secondAppPath = "cozie://" ///coziewatch
    
    var body: some View {
        ZStack{
            ZStack{
                HeartAnimation()
                
    //            GeometryReader { geometry in
    //                Image("Asset 3" )
    //                    .scaleEffect(0.5)
    //                    .offset(x:geometry.size.width-40, y:geometry.size.height)
    //            }
                
                GeometryReader { geometry in
                    ForEach(0..<cogIntensity, id: \.self) { index in
                        let seed = Bool.random()
                        Image("Asset " + String(Int.random(in: 1...18)))
                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                            .scaleEffect(0.2)
                            .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                            .offset(x: self.randomPosition(geometry: geometry, seed: seed).x, y: self.randomPosition(geometry: geometry, seed: seed).y)
                            .shadow(
                                color:Color.pink.opacity(0.5),
                                radius:4)
                            .animation(Animation.easeIn(duration: 1).delay(1))
                            
                    }
                }
                    
    //            GeometryReader { geometry in
    //                ForEach(0..<cogIntensity, id: \.self) { index in
    //                    let seed = Bool.random()
    //                    Image("Asset " + String(Int.random(in: 1...18)))
    //                        .scaleEffect(0.2)
    //                        .offset(x: self.randomPosition(geometry: geometry, seed: seed).x, y: self.randomPosition(geometry: geometry, seed: seed).y)
    //                        .shadow(
    //                            color:Color.pink.opacity(0.5),
    //                            radius:4)
    //                }
    //            }
                
            }
            .blur(radius: isSurvey ? 20 : 0)
            
            if(isSurvey){
                VStack(spacing: 20){
                    Text("Fill in a survey to unlock the AirSpec App")
                    
                    
//                    let appUrl = URL(string:secondAppPath)!
//                    Link("Go to Cozie", destination: appUrl)
//                        .buttonStyle(.borderedProminent)
                    
                    Button(action:{
                        withAnimation{
//                            let appUrl = URL(string:secondAppPath)!
                            
//                            openURL(appUrl) ///  SPApplicationDelegate extensionConnection:openSystemURL:]:2401: URL with scheme "coziewatch" not supported
//                            WKExtension.shared().openSystemURL(appUrl)
//                            NSExtensionContext().open(appUrl)
//                            if NSExtensionContext().canOpenURL(appUrl){
//                                NSExtensionContext().open(appUrl)
//                            }else{
//                                print("cannot find cozie app")
//                            }
                            
                            if let appURL = URL(string:secondAppPath) {
                                WKExtension.shared().openSystemURL(appURL)
                            } else {
                                print("Invalid URL specified.")
                            }

                            isSurvey.toggle()
                        }
                    }) {
                        Text("Go to Cozie")
                        .font(.system(.subheadline) .weight(.semibold))
                        .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 40)
//                    .padding(.all,20)
                    .background(.pink)
                    .clipShape(Capsule())
                    
                }
            }


        }
        

//        .blendMode(.darken)
        
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                timer = DispatchSource.makeTimerSource()
                timer?.schedule(deadline: .now(), repeating: .seconds(updateFrequence))
                timer?.setEventHandler {
                    startQueries()
                }
                timer?.resume()
            }else{
                timer?.cancel()
                timer = nil
            }
        }
        
        .onAppear{
            print("Active")
            timer = DispatchSource.makeTimerSource()
            timer?.schedule(deadline: .now(), repeating: .seconds(updateFrequence))
            timer?.setEventHandler {
                startQueries()
            }
            timer?.resume()
        }
        
        .onDisappear{
            timer?.cancel()
            timer = nil
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
    

    /// - get data from influxdb
    func startQueries() {
        DispatchQueue.global().async {
            let query_cog = """
                            from(bucket: "\(NetworkConstants.bucket)")
                            |> range(start: -2m)
                            |> filter(fn: (r) => r["_measurement"] == "thermopile_nose_tip"
                                    or r["_measurement"] == "thermopile_nose_bridge"
                                    or r["_measurement"] == "thermopile_temple_front"
                                    or r["_measurement"] == "thermopile_temple_middle"
                                    or r["_measurement"] == "thermopile_temple_back")
                            |> filter(fn: (r) => r["_field"] == "signal")
                            |> filter(fn: (r) => r["id"] == "\(user_id)")
                            |> filter(fn: (r) => r["type"] == "objectTemp")
                            |> mean()
                    """
            
            influxClient.queryAPI.query(query: query_cog, org: NetworkConstants.org) {response, error in
                // Error response
                if let error = error {
                    print("Error:\n\n\(error)")
                }
                
                // Success response
                if let response = response {
                    
                    print("\nSuccess response...\n")
                    var count  = 0
                    do {
                        try response.forEach { record in
                            DispatchQueue.main.async {
                                var skinTempIndex = skinTempDataName.index(of: "\(record.values["_measurement"]!)")
                                skinTempData[skinTempIndex!] = Double("\(record.values["_value"]!)") ?? 0.0
                            }
                        }
                        cogIntensity = Int(abs(skinTempData[4] - skinTempData[0])*10+5)
//                        print(cogIntensity)
//                        print(skinTempData[4] - skinTempData[0]) /// middle - bridge
                    } catch {
                        print("Error:\n\n\(error)")
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
    static var previews: some View {
        WatchHomeView()
    }
}





