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
    
    @State private var VisualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
    @State private var VisualDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorVisual.count)
    var user_id:String = "9067133"

    let updateFrequence = 10 /// seconds
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Visual")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
                ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 5) {
                    ForEach(0..<SensorIconConstants.sensorVisual.count){i in
                        VStack{
                            Text("\(Int(VisualData[i]))")
                                .font(.system(size: 10, design: .rounded) .weight(.heavy))
                                .foregroundColor(Color.white)
                            OpenCircularGauge(
                                current: VisualData[i],
                                minValue: SensorIconConstants.sensorVisual[i].minValue,
                                maxValue: SensorIconConstants.sensorVisual[i].maxValue,
                                color1: SensorIconConstants.sensorVisual[i].color1,
                                color2: SensorIconConstants.sensorVisual[i].color2,
                                color3: SensorIconConstants.sensorVisual[i].color3,
                                color1Position: SensorIconConstants.sensorVisual[i].color1Position,
                                color3Position: SensorIconConstants.sensorVisual[i].color3Position,
                                valueTrend: VisualDataTrend[i],
                                icon: SensorIconConstants.sensorVisual[i].icon){
                                }
                            

                                Text(SensorIconConstants.sensorVisual[i].name)
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
    }
}


struct VisualView_Previews: PreviewProvider {
    static var previews: some View {
        VisualView()
    }
}









