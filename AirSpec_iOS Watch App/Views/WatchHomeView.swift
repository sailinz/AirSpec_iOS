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
    
    @State private var cogIntensity = 1 /// must scale to a int
    let updateFrequence = 10 /// seconds
    ///
    
    var body: some View {
        VStack{
            ZStack{
                GeometryReader { geometry in
                    ForEach(0..<cogIntensity, id: \.self) { index in
                        Image("Asset " + String(Int.random(in: 1...18)))
                            .scaleEffect(0.5)
                            .offset(x: self.randomX(geometry: geometry), y: self.randomY(geometry: geometry))
                            .shadow(
                                color:Color.pink.opacity(0.5),
                                radius:4)
                    }
                }
                HeartAnimation()
            }
        }
        
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
    
    /// to render the cog load
    func randomX(geometry: GeometryProxy) -> CGFloat {
        // Generate a random x coordinate within the bounds of the view
        return CGFloat.random(in: 0...geometry.size.width)
    }
    
    func randomY(geometry: GeometryProxy) -> CGFloat {
        // Generate a random y coordinate within the bounds of the view
        return CGFloat.random(in: 0...geometry.size.height)
    }

    /// - get data from influxdb
    func startQueries() {
        DispatchQueue.global().async {
            var query_cog = """
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





