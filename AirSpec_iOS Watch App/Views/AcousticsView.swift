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

struct AcousticsView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive = false
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    let influxClient = try InfluxDBClient(url: NetworkConstants.url, token: NetworkConstants.token)
    @State private var timer: DispatchSourceTimer?
    @State private var AcousticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)
    @State private var AcousticsDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAcoustics.count)
    var user_id:String = "9067133"

    let updateFrequence = 10 /// seconds
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Acoustics")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 5) {
                    ForEach(0..<SensorIconConstants.sensorAcoustics.count){i in
                        VStack{
                            Text("\(Int(AcousticsData[i]))")
                                .font(.system(size: 10, design: .rounded) .weight(.heavy))
                                .foregroundColor(Color.white)
                            OpenCircularGauge(
                                current: AcousticsData[i],
                                minValue: SensorIconConstants.sensorAcoustics[i].minValue,
                                maxValue: SensorIconConstants.sensorAcoustics[i].maxValue,
                                color1: SensorIconConstants.sensorAcoustics[i].color1,
                                color2: SensorIconConstants.sensorAcoustics[i].color2,
                                color3: SensorIconConstants.sensorAcoustics[i].color3,
                                color1Position: SensorIconConstants.sensorAcoustics[i].color1Position,
                                color3Position: SensorIconConstants.sensorAcoustics[i].color3Position,
                                valueTrend: AcousticsDataTrend[i],
                                icon: SensorIconConstants.sensorAcoustics[i].icon){
                                }
                            

                                Text(SensorIconConstants.sensorAcoustics[i].name)
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 10))
//                                    .scaledToFit()
//                                    .minimumScaleFactor(0.01)
//                                    .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal)
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

    /// - get data from influxdb
    func startQueries() {
        let sensorList = [SensorIconConstants.sensorAcoustics,SensorIconConstants.sensorAcoustics, SensorIconConstants.sensorVisual]
//        var dataList = [AcousticsData, AcousticsData, visualData]
        
        /// environmental sensing
        DispatchQueue.global().async {
            let i = 0 /// available yet
            for j in 0..<sensorList[i].count{

                var query = """
                                from(bucket: "\(NetworkConstants.bucket)")
                                |> range(start: -2m)
                                |> filter(fn: (r) => r["_measurement"] == "\(sensorList[i][j].measurement)")
                                |> filter(fn: (r) => r["_field"] == "signal")
                                |> filter(fn: (r) => r["id"] == "\(user_id)")
                                |> filter(fn: (r) => r["\(sensorList[i][j].identifier)"] == "\(sensorList[i][j].type)")
                                |> mean()
                        """
                
                
                influxClient.queryAPI.query(query: query, org: NetworkConstants.org) {response, error in
                    // Error response
                    if let error = error {
                        print("Error:\n\n\(error)")
                    }
                    
                    // Success response
                    if let response = response {
                        
                        print("\nSuccess response...\n")
                        do {
                            try response.forEach { record in
                                DispatchQueue.main.async {
                                    AcousticsData[j] = Double("\(record.values["_value"]!)") ?? 0.0
                                    AcousticsDataTrend[j] = Int.random(in: -2 ..< 2)
//                                            print(record.values["_value"]!)
                                }
                            }
                        } catch {
                            print("Error:\n\n\(error)")
                        }
                    }
                }
            }
            
        }
    }
    
}


struct AcousticsView_Previews: PreviewProvider {
    static var previews: some View {
        AcousticsView()
    }
}








