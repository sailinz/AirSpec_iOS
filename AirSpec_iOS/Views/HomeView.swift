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

let screenWidth = UIScreen.main.bounds.width

struct HomeView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive = false
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

//    let influxClient = try InfluxDBClient(url: NetworkConstants.url, token: NetworkConstants.token)

//    @State private var timer: DispatchSourceTimer?


    //    @State var current: Double = 60.0
    //    @State var minValue: Double = 50.0
    //    @State var maxValue: Double = 100.0
    //    @State var color1:Color = Color.blue
    //    @State var color2:Color = Color.white
    //    @State var color3:Color = Color.red
    //    @State var color1Position: Double = 0.1
    //    @State var color3Position: Double = 0.9
    
    @EnvironmentObject private var receiver: BluetoothReceiver

    
    let skinTempDataName = ["thermopile_nose_bridge","thermopile_nose_tip","thermopile_temple_back","thermopile_temple_front","thermopile_temple_middle"]
    @State private var skinTempData = Array(repeating: -1.0, count: 5)
    var user_id:String = "9067133"

    @State private var thermalDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorThermal.count)
    @State private var airQualityDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAirQuality.count)
    @State private var visualDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorVisual.count)
    @State private var acoutsticsDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAcoustics.count)
    @State private var cogIntensity = 1 /// must scale to a int
    let updateFrequence = 10 /// seconds


    ///get user set comfort range from userdefault
//    @State private var color1PositionThermal = [UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
//    @State private var color3PositionThermal = [UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
//    @State private var color1PositionVisual = [UserDefaults.standard.double(forKey: "minValueLightIntensity")]
//    @State private var color3PositionVisual = [UserDefaults.standard.double(forKey: "maxValueLightIntensity")]
//    @State private var color1PositionAcoutstics = [UserDefaults.standard.double(forKey: "minValueNoise"), UserDefaults.standard.double(forKey: "minValueNoise")]
//    @State private var color3PositionAcoutstics = [UserDefaults.standard.double(forKey: "maxValueNoise"), UserDefaults.standard.double(forKey: "maxValueNoise")]

    @State private var color1PositionThermal: [Double]?
    @State private var color3PositionThermal: [Double]?
    @State private var color1PositionVisual: [Double]?
    @State private var color3PositionVisual: [Double]?
    @State private var color1PositionAcoutstics: [Double]?
    @State private var color3PositionAcoutstics: [Double]?



    var body: some View {

        NavigationView{
            VStack{
//                Text("Home")
//                    .font(
//                            .custom(
//                            "SF Pro Display",
//                            fixedSize: 30)
//                            .weight(.heavy)
//                        )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()
//                //                List {
//                //                    Section(header: Text("Temperature")){
//                ////                        showDataFromInflux
//                //                    }
//                //                }
//
                ZStack{

                    GeometryReader { geometry in
                        ForEach(0..<cogIntensity, id: \.self) { index in
                            Image("Asset " + String(Int.random(in: 1...18)))
                                .rotationEffect(.degrees(Double.random(in: 0...360)))
                                .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                                .offset(x: self.randomX(geometry: geometry), y: self.randomY(geometry: geometry))
                                .shadow(
                                    color:Color.pink.opacity(0.5),
                                    radius:4)
                                .animation(Animation.easeIn(duration: 1).delay(1))

                        }
                    }

                    ScrollView {

            //            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        HeartAnimation()
                            .padding(.all, 80)

                        /// Thermal
                        VStack (alignment: .leading) {
                            Text("Thermal")
                                .font(.system(.title2) .weight(.heavy))
                                .padding()
                            LazyVGrid(columns: columns, spacing: 5) {
                                ForEach(0..<SensorIconConstants.sensorThermal.count){i in
                                    HStack{
                                        OpenCircularGauge(
                                            current: receiver.thermalData[i],
                                            minValue: SensorIconConstants.sensorThermal[i].minValue,
                                            maxValue: SensorIconConstants.sensorThermal[i].maxValue,
                                            color1: SensorIconConstants.sensorThermal[i].color1,
                                            color2: SensorIconConstants.sensorThermal[i].color2,
                                            color3: SensorIconConstants.sensorThermal[i].color3,
                                            color1Position: color1PositionThermal?[i] ?? SensorIconConstants.sensorThermal[i].color1Position,
                                            color3Position: color3PositionThermal?[i] ?? SensorIconConstants.sensorThermal[i].color3Position,
                                            valueTrend: thermalDataTrend[i],
                                            icon: SensorIconConstants.sensorThermal[i].icon){
                                            }

                                        VStack (alignment: .leading) {
                                            Text(SensorIconConstants.sensorThermal[i].name)
                                                .foregroundColor(Color.white)
                                                .font(.system(size: 13))
//                                                .scaledToFit()
//                                                .minimumScaleFactor(0.01)
//                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(receiver.thermalData[i]))")
                                                .font(.system(.title, design: .rounded) .weight(.heavy))
                                                .foregroundColor(Color.white)
                                        }
                                    }
                                    .frame(minWidth: screenWidth/2 - 50, alignment: .leading)
                                    .padding(.all, 11)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(15)
                                    .shadow(
                                        color:Color.pink.opacity(0.4),
                                        radius: 4)
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
                                            current: receiver.airQualityData[i],
                                            minValue: SensorIconConstants.sensorAirQuality[i].minValue,
                                            maxValue: SensorIconConstants.sensorAirQuality[i].maxValue,
                                            color1: SensorIconConstants.sensorAirQuality[i].color1,
                                            color2: SensorIconConstants.sensorAirQuality[i].color2,
                                            color3: SensorIconConstants.sensorAirQuality[i].color3,
                                            color1Position: SensorIconConstants.sensorAirQuality[i].color1Position,
                                            color3Position: SensorIconConstants.sensorAirQuality[i].color3Position,
                                            valueTrend: airQualityDataTrend[i],
                                            icon: SensorIconConstants.sensorAirQuality[i].icon){
                                            }

                                        VStack (alignment: .leading) {
                                            Text(SensorIconConstants.sensorAirQuality[i].name)
                                                .foregroundColor(Color.white)
                                                .font(.system(size: 12))
//                                                .frame(minWidth: 60)
//
//                                                .scaledToFit()
//                                                .minimumScaleFactor(0.01)
//                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(receiver.airQualityData[i]))")
                                                .font(.system(.title, design: .rounded) .weight(.heavy))
                                                .foregroundColor(Color.white)
                                        }
                                    }
                                    .frame(minWidth: screenWidth/2 - 50, alignment: .leading)
                                    .padding(.all, 11)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(15)
                                    .shadow(
                                        color:Color.pink.opacity(0.4),
                                        radius: 4)
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
                                            current: receiver.visualData[i],
                                            minValue: SensorIconConstants.sensorVisual[i].minValue,
                                            maxValue: SensorIconConstants.sensorVisual[i].maxValue,
                                            color1: SensorIconConstants.sensorVisual[i].color1,
                                            color2: SensorIconConstants.sensorVisual[i].color2,
                                            color3: SensorIconConstants.sensorVisual[i].color3,
                                            color1Position: color1PositionVisual?[i] ?? SensorIconConstants.sensorVisual[i].color1Position,
                                            color3Position: color3PositionVisual?[i] ?? SensorIconConstants.sensorVisual[i].color1Position,
                                            valueTrend: visualDataTrend[i],
                                            icon: SensorIconConstants.sensorVisual[i].icon){
                                            }

                                        VStack (alignment: .leading) {
                                            Text(SensorIconConstants.sensorVisual[i].name)
                                                .foregroundColor(Color.white)
                                                .font(.system(size: 12))
//                                                .frame(minWidth: 60)
//                                                .scaledToFit()
//                                                .minimumScaleFactor(0.01)
//                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(receiver.visualData[i]))")
                                                .font(.system(.title, design: .rounded) .weight(.heavy))
                                                .foregroundColor(Color.white)
                                        }
                                    }
                                    .frame(minWidth: screenWidth/2 - 50, alignment: .leading)
                                    .padding(.all, 11)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(15)
                                    .shadow(
                                        color:Color.pink.opacity(0.4),
                                        radius: 4)
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
                                            minValue: SensorIconConstants.sensorAcoustics[i].minValue,
                                            maxValue: SensorIconConstants.sensorAcoustics[i].maxValue,
                                            color1: SensorIconConstants.sensorAcoustics[i].color1,
                                            color2: SensorIconConstants.sensorAcoustics[i].color2,
                                            color3: SensorIconConstants.sensorAcoustics[i].color3,
                                            color1Position: color1PositionAcoutstics?[i] ?? SensorIconConstants.sensorAcoustics[i].color1Position,
                                            color3Position: color3PositionAcoutstics?[i] ?? SensorIconConstants.sensorAcoustics[i].color3Position,
                                            valueTrend: 0,
                                            icon: SensorIconConstants.sensorAcoustics[i].icon){
                                            }

                                        VStack (alignment: .leading) {
                                            Text(SensorIconConstants.sensorAcoustics[i].name)
                                                .foregroundColor(Color.white)
                                                .font(.system(size: 12))
//                                                .scaledToFit()
//                                                .minimumScaleFactor(0.01)
//                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(dummyValue))")
                                                .font(.system(.title, design: .rounded) .weight(.heavy))
                                                .foregroundColor(Color.white)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(minWidth: screenWidth/2 - 50, alignment: .leading)
                                    .padding(.all, 11)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(15)
                                    .shadow(
                                        color:Color.pink.opacity(0.4),
                                        radius: 4)

                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Home")
        }

        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                /// get user's comfort range
                color1PositionThermal = [UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
                color3PositionThermal = [UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
                color1PositionVisual = [UserDefaults.standard.double(forKey: "minValueLightIntensity")]
                color3PositionVisual = [UserDefaults.standard.double(forKey: "maxValueLightIntensity")]
                color1PositionAcoutstics = [UserDefaults.standard.double(forKey: "minValueNoise"), UserDefaults.standard.double(forKey: "minValueNoise")]
                color3PositionAcoutstics = [UserDefaults.standard.double(forKey: "maxValueNoise"), UserDefaults.standard.double(forKey: "maxValueNoise")]

                /// retrieve data from influxdb
//                timer = DispatchSource.makeTimerSource()
//                timer?.schedule(deadline: .now(), repeating: .seconds(updateFrequence))
//                timer?.setEventHandler {
//                    startQueries()
//                }
//                timer?.resume()


            }else{

//                timer?.cancel()
//                timer = nil
            }
        }

        .onAppear{
            print("Active")
            /// get user's comfort range
            color1PositionThermal = [UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
            color3PositionThermal = [UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
            color1PositionVisual = [UserDefaults.standard.double(forKey: "minValueLightIntensity")]
            color3PositionVisual = [UserDefaults.standard.double(forKey: "maxValueLightIntensity")]
            color1PositionAcoutstics = [UserDefaults.standard.double(forKey: "minValueNoise"), UserDefaults.standard.double(forKey: "minValueNoise")]
            color3PositionAcoutstics = [UserDefaults.standard.double(forKey: "maxValueNoise"), UserDefaults.standard.double(forKey: "maxValueNoise")]

            /// retrieve data from influxdb
//            timer = DispatchSource.makeTimerSource()
//            timer?.schedule(deadline: .now(), repeating: .seconds(updateFrequence))
//            timer?.setEventHandler {
//                startQueries()
//            }
//            timer?.resume()


        }

//        .onDisappear{
//            timer?.cancel()
//            timer = nil
//        }
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
//    func startQueries() {
//        let sensorList = [SensorIconConstants.sensorThermal,SensorIconConstants.sensorAirQuality, SensorIconConstants.sensorVisual]
//
//        /// environmental sensing
//        DispatchQueue.global().async {
//            for i in 0..<sensorList.count{
//                for j in 0..<sensorList[i].count{
//                    var query = """
//                                """
//
//
//                    if(i == 2){ ///lux has no type
//                        query = """
//                                        from(bucket: "\(NetworkConstants.bucket)")
//                                        |> range(start: -2m)
//                                        |> filter(fn: (r) => r["_measurement"] == "\(sensorList[i][j].measurement)")
//                                        |> filter(fn: (r) => r["_field"] == "signal")
//                                        |> filter(fn: (r) => r["id"] == "\(user_id)")
//                                        |> mean()
//                                """
//                    }else{
//                        query = """
//                                        from(bucket: "\(NetworkConstants.bucket)")
//                                        |> range(start: -2m)
//                                        |> filter(fn: (r) => r["_measurement"] == "\(sensorList[i][j].measurement)")
//                                        |> filter(fn: (r) => r["_field"] == "signal")
//                                        |> filter(fn: (r) => r["id"] == "\(user_id)")
//                                        |> filter(fn: (r) => r["\(sensorList[i][j].identifier)"] == "\(sensorList[i][j].type)")
//                                        |> mean()
//                                """
//                    }
//
//                    influxClient.queryAPI.query(query: query, org: NetworkConstants.org) {response, error in
//                        // Error response
//                        if let error = error {
//                            print("Error:\n\n\(error)")
//                        }
//
//                        // Success response
//                        if let response = response {
//
//                            print("\nSuccess response...\n")
//                            do {
//                                try response.forEach { record in
//                                    DispatchQueue.main.async {
//                                        if i == 0 {
//                                            thermalData[j] = Double("\(record.values["_value"]!)") ?? 0.0
//                                            thermalDataTrend[j] = Int.random(in: -2 ..< 2)
//                                        }else if i == 1{
//                                            airQualityData[j] = Double("\(record.values["_value"]!)") ?? 0.0
//                                            airQualityDataTrend[j] = Int.random(in: -2 ..< 2)
//                                        }else if i == 2{
//                                            visualData[j] = Double("\(record.values["_value"]!)") ?? 0.0
//                                            visualDataTrend[j] = Int.random(in: -2 ..< 2)
//                                        }else if i == 3{
//                                            /// placeholder for noise value
//                                        }else{
//
//                                        }
//
//                                    }
//                                }
//                            } catch {
//                                print("Error:\n\n\(error)")
//                            }
//                        }
//                    }
//
//
//                }
//            }
//        }
//
//        DispatchQueue.global().async {
//            var query_cog = """
//                            from(bucket: "\(NetworkConstants.bucket)")
//                            |> range(start: -2m)
//                            |> filter(fn: (r) => r["_measurement"] == "thermopile_nose_tip"
//                                    or r["_measurement"] == "thermopile_nose_bridge"
//                                    or r["_measurement"] == "thermopile_temple_front"
//                                    or r["_measurement"] == "thermopile_temple_middle"
//                                    or r["_measurement"] == "thermopile_temple_back")
//                            |> filter(fn: (r) => r["_field"] == "signal")
//                            |> filter(fn: (r) => r["id"] == "\(user_id)")
//                            |> filter(fn: (r) => r["type"] == "objectTemp")
//                            |> mean()
//                    """
//
//            influxClient.queryAPI.query(query: query_cog, org: NetworkConstants.org) {response, error in
//                // Error response
//                if let error = error {
//                    print("Error:\n\n\(error)")
//                }
//
//                // Success response
//                if let response = response {
//
//                    print("\nSuccess response...\n")
//                    var count  = 0
//                    do {
//                        try response.forEach { record in
//                            DispatchQueue.main.async {
//                                var skinTempIndex = skinTempDataName.index(of: "\(record.values["_measurement"]!)")
//                                skinTempData[skinTempIndex!] = Double("\(record.values["_value"]!)") ?? 0.0
//                            }
//                        }
//                        cogIntensity = Int(abs(skinTempData[4] - skinTempData[0])*10+5) /// middle - bridge
//                    } catch {
//                        print("Error:\n\n\(error)")
//                    }
//                }
//            }
//        }
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


