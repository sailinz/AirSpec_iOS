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
    
//    @ObservedObject var viewModel : ProgramViewModel
//    @State var sensorValues : ProgramObject
    
//    @State private var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
    @State private var thermalDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorThermal.count)
//    var user_id:String = "9067133"

//    let updateFrequence = 10 /// seconds
    
    /// -- watch connectivity
//    @StateObject var dataReceivedWatch = SensorData()  /// need to find more efficient ways to receive these data
    @ObservedObject var dataReceivedWatch: SensorData
    
    var body: some View {
        VStack (alignment: .leading) {
            
            Text("Thermal")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
//            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 3) {
                    ForEach(0..<SensorIconConstants.sensorThermal.count){i in
                        VStack{
//                            Text(Int(dataReceivedWatch.sensorValueNew[0][i]) == -1 ? "" : "\(Int(dataReceivedWatch.sensorValueNew[0][i]))")
//                                .font(.system(size: 10, design: .rounded) .weight(.heavy))
//                                .foregroundColor(Color.white)
                            OpenCircularGauge(
                                current: dataReceivedWatch.sensorValueNew[0][i],
                                minValue: SensorIconConstants.sensorThermal[i].minValue,
                                maxValue: SensorIconConstants.sensorThermal[i].maxValue,
                                color1: SensorIconConstants.sensorThermal[i].color1,
                                color2: SensorIconConstants.sensorThermal[i].color2,
                                color3: SensorIconConstants.sensorThermal[i].color3,
                                color1Position: SensorIconConstants.sensorThermal[i].color1Position,
                                color3Position: SensorIconConstants.sensorThermal[i].color3Position,
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
//            }
        }
//        .onAppear(){
//            viewModel.connectivityProvider.connect()
//            self.sensorValues = viewModel.connectivityProvider.receivedPrograms!
//        }
    }
    
}


//struct ThermalView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThermalView()
//    }
//}






