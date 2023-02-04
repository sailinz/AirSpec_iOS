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


struct AirQualityView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive = false
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    
    @State private var AirQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
    @State private var AirQualityDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAirQuality.count)
    var user_id:String = "9067133"

    let updateFrequence = 10 /// seconds
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Air quality")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
                ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 5) {
                    ForEach(0..<SensorIconConstants.sensorAirQuality.count){i in
                        VStack{
                            Text("\(Int(AirQualityData[i]))")
                                .font(.system(size: 10, design: .rounded) .weight(.heavy))
                                .foregroundColor(Color.white)
                            OpenCircularGauge(
                                current: AirQualityData[i],
                                minValue: SensorIconConstants.sensorAirQuality[i].minValue,
                                maxValue: SensorIconConstants.sensorAirQuality[i].maxValue,
                                color1: SensorIconConstants.sensorAirQuality[i].color1,
                                color2: SensorIconConstants.sensorAirQuality[i].color2,
                                color3: SensorIconConstants.sensorAirQuality[i].color3,
                                color1Position: SensorIconConstants.sensorAirQuality[i].color1Position,
                                color3Position: SensorIconConstants.sensorAirQuality[i].color3Position,
                                valueTrend: AirQualityDataTrend[i],
                                icon: SensorIconConstants.sensorAirQuality[i].icon){
                                }
                            

                                Text(SensorIconConstants.sensorAirQuality[i].name)
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


struct AirQualityView_Previews: PreviewProvider {
    static var previews: some View {
        AirQualityView()
    }
}







