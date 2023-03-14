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
    
    @State private var AcousticsDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAcoustics.count)


    let updateFrequence = 10 /// seconds
    @ObservedObject var dataReceivedWatch: SensorData
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Acoustics")
                .font(.system(.caption2) .weight(.heavy))
                .padding()
            LazyVGrid(columns: columns, alignment: .center, spacing: 3) {
                ForEach(0..<SensorIconConstants.sensorAcoustics.count){i in
                    VStack{
                        OpenCircularGauge(
                            current: dataReceivedWatch.sensorValueNew[3][i], //AcousticsData[i],
                            minValue: SensorIconConstants.sensorAcoustics[i].minValue,
                            maxValue: SensorIconConstants.sensorAcoustics[i].maxValue,
                            color1: SensorIconConstants.sensorAcoustics[i].color1,
                            color2: SensorIconConstants.sensorAcoustics[i].color2,
                            color3: SensorIconConstants.sensorAcoustics[i].color3,
                            color1Position: dataReceivedWatch.sensorValueNew[9][i],
                            color3Position: dataReceivedWatch.sensorValueNew[10][i],
                            valueTrend: AcousticsDataTrend[i],
                            icon: SensorIconConstants.sensorAcoustics[i].icon){
                            }
                        

                            Text(SensorIconConstants.sensorAcoustics[i].name)
                                .foregroundColor(Color.white)
                                .font(.system(size: 10))
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear{
            RawDataViewModel.addMetaDataToRawData(payload: "Noise clicked on watch", timestampUnix: Date(), type: 1)
        }
    }
}


//struct AcousticsView_Previews: PreviewProvider {
//    static var previews: some View {
//        AcousticsView()
//    }
//}








