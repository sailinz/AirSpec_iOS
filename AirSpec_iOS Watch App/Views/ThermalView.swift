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

struct ThermalView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive = false
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    @State private var thermalDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorThermal.count)
    
    /// -- watch connectivity
    @ObservedObject var dataReceivedWatch: SensorData
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Thermal")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
            LazyVGrid(columns: columns, alignment: .center, spacing: 3) {
                ForEach(0..<SensorIconConstants.sensorThermal.count){i in
                    VStack{
                        OpenCircularGauge(
                            current: dataReceivedWatch.sensorValueNew[0][safe: i] ?? -1,
                            minValue: SensorIconConstants.sensorThermal[i].minValue,
                            maxValue: SensorIconConstants.sensorThermal[i].maxValue,
                            color1: SensorIconConstants.sensorThermal[i].color1,
                            color2: SensorIconConstants.sensorThermal[i].color2,
                            color3: SensorIconConstants.sensorThermal[i].color3,
                            color1Position: dataReceivedWatch.sensorValueNew[5][safe: i] ?? SensorIconConstants.sensorThermal[i].color1Position,
                            color3Position: dataReceivedWatch.sensorValueNew[6][safe: i] ?? SensorIconConstants.sensorThermal[i].color3Position,
                            valueTrend: thermalDataTrend[i],
                            icon: SensorIconConstants.sensorThermal[i].icon){
                            }
                        

                            Text(SensorIconConstants.sensorThermal[i].name)
                                .foregroundColor(Color.white)
                                .font(.system(size: 10))
                    }
                        
                }
            }
            .padding(.horizontal)
        }
        .onAppear(){
            RawDataViewModel.addMetaDataToRawData(payload: "Thermal clicked on watch", timestampUnix: Date(), type: 1)
        }
    }
    
}

//
//struct ThermalView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThermalView()
//    }
//}






