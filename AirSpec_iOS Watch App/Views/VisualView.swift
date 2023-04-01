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

struct VisualView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive = false
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    @State private var VisualDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorVisual.count)
    
    
    @ObservedObject var dataReceivedWatch: SensorData
        
    var body: some View {
        VStack (alignment: .leading) {
            Text("Visual")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 3) {
                    
                    ForEach(0..<SensorIconConstants.sensorVisual.count){i in
                        ZStack{
                            if(SensorIconConstants.sensorVisual[i].name.contains("eye")){
                                Image(systemName: "eye")
                                    .renderingMode(.template)
                                    .foregroundColor(SensorIconConstants.customColor)
                                    .opacity(0.5)
                                    .font(.system(size: 30))
                            }
                            VStack{
                                OpenCircularGauge(
                                    current: dataReceivedWatch.sensorValueNew[2][safe: i] ?? -1,
                                    minValue: SensorIconConstants.sensorVisual[i].minValue,
                                    maxValue: SensorIconConstants.sensorVisual[i].maxValue,
                                    color1: SensorIconConstants.sensorVisual[i].color1,
                                    color2: SensorIconConstants.sensorVisual[i].color2,
                                    color3: SensorIconConstants.sensorVisual[i].color3,
                                    color1Position: dataReceivedWatch.sensorValueNew[7][safe: i] ?? SensorIconConstants.sensorVisual[i].color1Position,
                                    color3Position: dataReceivedWatch.sensorValueNew[8][safe: i] ?? SensorIconConstants.sensorVisual[i].color3Position,
                                    valueTrend: VisualDataTrend[i],
                                    icon: SensorIconConstants.sensorVisual[i].icon){
                                    }
                                

                                    Text(SensorIconConstants.sensorVisual[i].name)
                                        .foregroundColor(Color.white)
                                        .font(.system(size: 10))
                            }
                        }
                        
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear{
            RawDataViewModel.addMetaDataToRawData(payload: "Visual clicked on watch", timestampUnix: Date(), type: 1)
        }
    }
}


//struct VisualView_Previews: PreviewProvider {
//    static var previews: some View {
//        VisualView()
//    }
//}
//








