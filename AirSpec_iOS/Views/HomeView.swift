//
//  Home.swift
//  AirSpec_Watch Watch App
//
//  Created by ZHONG Sailin on 03.11.22.
//  developer.apple.com/videos/play/wwdc2021/10005
import SwiftUI

struct HomeView: View {
    
//    @EnvironmentObject private var receiver: BluetoothReceiver
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
//
//    @State var current: Double = 60.0
//    @State var minValue: Double = 50.0
//    @State var maxValue: Double = 100.0
//    @State var color1:Color = Color.blue
//    @State var color2:Color = Color.white
//    @State var color3:Color = Color.red
//    @State var color1Position: Double = 0.1
//    @State var color3Position: Double = 0.9

    var body: some View {

        NavigationView{
            VStack{
                //                List {
                //                    Section(header: Text("Temperature")){
                ////                        showDataFromInflux
                //                    }
                //                }
                
                ScrollView {
                    
                    /// Termal
                    VStack (alignment: .leading) {
                        Text("Thermal")
                            .font(.system(.title2) .weight(.heavy))
                            .padding()
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(0..<SensorIconConstants.sensorThermal.count){i in
                                let dummyValue = Double.random(in: 50.0 ..< 80.0)
                                HStack{
                                    OpenCircularGauge(
                                        current: dummyValue,
                                        minValue: Double.random(in: 10.0 ..< 45.0),
                                        maxValue: Double.random(in: 80.0 ..< 100.0),
                                        color1: SensorIconConstants.sensorThermal[i].color1,
                                        color2: SensorIconConstants.sensorThermal[i].color2,
                                        color3: SensorIconConstants.sensorThermal[i].color3,
                                        color1Position: Double.random(in: 0.1 ..< 0.5),
                                        color3Position: Double.random(in: 0.6 ..< 1.0),
                                        valueTrend: Int.random(in: -2 ..< 2),
                                        icon: SensorIconConstants.sensorThermal[i].icon){
                                        }
                                    
                                    VStack (alignment: .leading) {
                                        Text(SensorIconConstants.sensorThermal[i].name)
                                            .foregroundColor(Color.white)
                                            .scaledToFit()
                                            .minimumScaleFactor(0.01)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(Int(dummyValue))")
                                            .font(.system(.title, design: .rounded) .weight(.heavy))
                                            .foregroundColor(Color.white)
                                    }
                                }
                                .padding()
//                                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 30))
                                .background(Color.black.opacity(0.9))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack (alignment: .leading) {
                        Text("Air quality")
                            .font(.system(.title2) .weight(.heavy))
                            .padding()
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(0..<SensorIconConstants.sensorAirQuality.count){i in
                                let dummyValue = Double.random(in: 50.0 ..< 80.0)
                                HStack{
                                    OpenCircularGauge(
                                        current: dummyValue,
                                        minValue: Double.random(in: 10.0 ..< 45.0),
                                        maxValue: Double.random(in: 80.0 ..< 100.0),
                                        color1: SensorIconConstants.sensorAirQuality[i].color1,
                                        color2: SensorIconConstants.sensorAirQuality[i].color2,
                                        color3: SensorIconConstants.sensorAirQuality[i].color3,
                                        color1Position: Double.random(in: 0.1 ..< 0.5),
                                        color3Position: Double.random(in: 0.6 ..< 1.0),
                                        valueTrend: Int.random(in: -2 ..< 2),
                                        icon: SensorIconConstants.sensorAirQuality[i].icon){
                                        }
                                    
                                    VStack (alignment: .leading) {
                                        Text(SensorIconConstants.sensorAirQuality[i].name)
                                            .foregroundColor(Color.white)
                                            .scaledToFit()
                                            .minimumScaleFactor(0.01)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(Int(dummyValue))")
                                            .font(.system(.title, design: .rounded) .weight(.heavy))
                                            .foregroundColor(Color.white)
                                    }
                                }
                                .padding()
//                                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 30))
                                .background(Color.black.opacity(0.9))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack (alignment: .leading) {
                        Text("Lighting")
                            .font(.system(.title2) .weight(.heavy))
                            .padding()
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(0..<SensorIconConstants.sensorVisual.count){i in
                                let dummyValue = Double.random(in: 50.0 ..< 80.0)
                                HStack{
                                    OpenCircularGauge(
                                        current: dummyValue,
                                        minValue: Double.random(in: 10.0 ..< 45.0),
                                        maxValue: Double.random(in: 80.0 ..< 100.0),
                                        color1: SensorIconConstants.sensorVisual[i].color1,
                                        color2: SensorIconConstants.sensorVisual[i].color2,
                                        color3: SensorIconConstants.sensorVisual[i].color3,
                                        color1Position: Double.random(in: 0.1 ..< 0.5),
                                        color3Position: Double.random(in: 0.6 ..< 1.0),
                                        valueTrend: Int.random(in: -2 ..< 2),
                                        icon: SensorIconConstants.sensorVisual[i].icon){
                                        }
                                    
                                    VStack (alignment: .leading) {
                                        Text(SensorIconConstants.sensorVisual[i].name)
                                            .foregroundColor(Color.white)
                                            .scaledToFit()
                                            .minimumScaleFactor(0.01)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(Int(dummyValue))")
                                            .font(.system(.title, design: .rounded) .weight(.heavy))
                                            .foregroundColor(Color.white)
                                    }
                                }
                                .padding()
//                                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 30))
                                .background(Color.black.opacity(0.9))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack (alignment: .leading) {
                        Text("Noise")
                            .font(.system(.title2) .weight(.heavy))
                            .padding()
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(0..<SensorIconConstants.sensorAcoustics.count){i in
                                let dummyValue = Double.random(in: 50.0 ..< 80.0)
                                HStack{
                                    OpenCircularGauge(
                                        current: dummyValue,
                                        minValue: Double.random(in: 10.0 ..< 45.0),
                                        maxValue: Double.random(in: 80.0 ..< 100.0),
                                        color1: SensorIconConstants.sensorAcoustics[i].color1,
                                        color2: SensorIconConstants.sensorAcoustics[i].color2,
                                        color3: SensorIconConstants.sensorAcoustics[i].color3,
                                        color1Position: Double.random(in: 0.1 ..< 0.5),
                                        color3Position: Double.random(in: 0.6 ..< 1.0),
                                        valueTrend: Int.random(in: -2 ..< 2),
                                        icon: SensorIconConstants.sensorAcoustics[i].icon){
                                        }
                                    
                                    VStack (alignment: .leading) {
                                        Text(SensorIconConstants.sensorAcoustics[i].name)
                                            .foregroundColor(Color.white)
                                            .scaledToFit()
                                            .minimumScaleFactor(0.01)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(Int(dummyValue))")
                                            .font(.system(.title, design: .rounded) .weight(.heavy))
                                            .foregroundColor(Color.white)
                                    }
                                }
                                .padding()
//                                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 30))
                                .background(Color.black.opacity(0.9))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    
                    
                    
                    
                }.navigationTitle("Home")
                
            }
        }
    }
    
    
//    var showDataFromInflux: some View {
//        Text(receiver.temperatureValue)
//    }
}

extension Color {
    static func random() -> Color {
        return Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}


