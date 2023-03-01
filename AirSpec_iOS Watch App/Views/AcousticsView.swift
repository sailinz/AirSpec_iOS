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
    
    @State private var AcousticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)
    @State private var AcousticsDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAcoustics.count)
//    var user_id:String = "9067133"

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
    }
}


struct AcousticsView_Previews: PreviewProvider {
    static var previews: some View {
        AcousticsView()
    }
}








