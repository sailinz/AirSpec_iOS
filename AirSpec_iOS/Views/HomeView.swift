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
        GridItem(.flexible()),
    ]

    
    @EnvironmentObject private var receiver: BluetoothReceiver
//    let dummyvalue:Double  = 10.0

    
    let skinTempDataName = ["thermopile_nose_bridge","thermopile_nose_tip","thermopile_temple_back","thermopile_temple_front","thermopile_temple_middle"]
    @State private var skinTempData = Array(repeating: -1.0, count: 5)

    @State private var thermalDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorThermal.count)
    @State private var airQualityDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAirQuality.count)
    @State private var visualDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorVisual.count)
    @State private var acoutsticsDataTrend = Array(repeating: -1, count: SensorIconConstants.sensorAcoustics.count)

    let updateFrequence = 10 /// seconds


    @State private var color1PositionThermal: [Double]?
    @State private var color3PositionThermal: [Double]?
    @State private var color1PositionVisual: [Double]?
    @State private var color3PositionVisual: [Double]?
    @State private var color1PositionAcoutstics: [Double]?
    @State private var color3PositionAcoutstics: [Double]?

    
    
//    let thermalBgImageAssets = ["Asset 15", "Asset 11"]
//    let airQualityBgImageAssets = ["Asset 6", "Asset 14", "Asset 4", "Asset 6", "Asset 14", "Asset 4"]
//    let visualBgImageAssets = ["Asset 10", "Asset 15", "Asset 11"]
//    let acousticsBgImageAssets = ["Asset 10"]
//
    let thermalBgImageAssets = ["Asset 15", "Asset 11"]
    let airQualityBgImageAssets = ["Asset 10", "Asset 14", "Asset 4", "Asset 15", "Asset 11", "Asset 6"]
    let visualBgImageAssets = ["Asset 10", "Asset 15", "Asset 11"]
    let acousticsBgImageAssets = ["Asset 10"]
    
    let scaleFactor = 0.9
    let fontSize:CGFloat = 12
    let bgScaleFactor = 2.9

    
    @State var isClickedThermal: Bool = false
    @State var isClickedAirQuality: Bool = false
    @State var isClickedVisual: Bool = false
    @State var isClickedNoise: Bool = false
    
    var body: some View {

        NavigationView{
            ZStack{
                

                GeometryReader { geometry in
                    ForEach(0..<receiver.cogIntensity, id: \.self) { index in //  Int(dummyvalue)
                        Image("Asset " + String(Int.random(in: 1...18)))
                            .opacity(0.6)
                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                            .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                            .offset(x: self.randomX(geometry: geometry), y: self.randomY(geometry: geometry))
                            .shadow(
                                color:Color.pink.opacity(0.5),
                                radius:4)
//                            .animation(Animation.easeIn(duration: 1).delay(1))
                            .animation(Animation.easeIn(duration: 2).delay(2)) ///week 2 experiment

                    }
                }
            
                
                VStack{
                    HeartAnimation( isClickedThermal: $isClickedThermal, isClickedAirQuality: $isClickedAirQuality, isClickedVisual: $isClickedVisual, isClickedNoise: $isClickedNoise)
                        .padding(.top, 30)
                        .padding(.bottom, 70)

//                    ScrollView {

                    if isClickedThermal{
                        withAnimation{
                            /// Thermal
                            VStack (alignment: .leading){
                                //                            Text("Thermal")
                                //                                .font(.system(size: 22) .weight(.heavy))
                                //                                .padding(.leading)
                                
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(0..<SensorIconConstants.sensorThermal.count){i in
                                        ZStack{
                                            Image(thermalBgImageAssets[i])
                                                .renderingMode(.template)
                                                .foregroundColor(SensorIconConstants.customColor)
                                                .opacity(0.7)
                                                .shadow(color: .pink, radius: 2)
                                                .scaleEffect(bgScaleFactor)
                                            
                                            VStack{
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
                                                
                                                Text(SensorIconConstants.sensorThermal[i].name)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color.white)
                                                    .font(.system(size: fontSize) .weight(.heavy))
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .shadow(
                                                        color:.black,
                                                        radius:10)
                                            }
                                            
                                        }
                                        .scaleEffect(scaleFactor)
                                    }
                                }
                                
                            }
                        }
                        
                    }
                    
                    if isClickedAirQuality{
                        withAnimation{
                            VStack (alignment: .trailing){
                                //                            Text("Air quality")
                                //                                .font(.system(size: 22) .weight(.heavy))
                                //                                .padding(.trailing)
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(0..<SensorIconConstants.sensorAirQuality.count){i in
                                        ZStack{
                                            Image(airQualityBgImageAssets[i])
                                                .renderingMode(.template)
                                                .foregroundColor(SensorIconConstants.customColor)
                                                .opacity(0.7)
                                                .shadow(color: .pink, radius: 2)
                                                .scaleEffect(bgScaleFactor)
                                            
                                            if(SensorIconConstants.sensorAirQuality[i].name.contains("nose")){
                                                Image(systemName: "nose.fill")
                                                    .renderingMode(.template)
                                                    .foregroundColor(SensorIconConstants.customColor)
                                                    .scaleEffect(bgScaleFactor)
                                            }
                                            
                                            VStack{
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
                                                
                                                Text(SensorIconConstants.sensorAirQuality[i].name)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color.white)
                                                    .font(.system(size: fontSize) .weight(.heavy))
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .shadow(
                                                        color:.black,
                                                        radius:10)
                                                
                                            }
                                            
                                        }
                                        .scaleEffect(scaleFactor)
                                        
                                    }
                                }
                            }

                        }
                    }
                        
                            
                    if isClickedVisual{
                        withAnimation{
                            VStack (alignment: .leading) {
                                //                            Text("Visual")
                                //                                .font(.system(size: 22) .weight(.heavy))
                                //                                .padding(.leading)
                                LazyVGrid(columns: columns, spacing: 1) {
                                    ForEach(0..<SensorIconConstants.sensorVisual.count){i in
                                        ZStack{
                                            Image(visualBgImageAssets[i])
                                                .renderingMode(.template)
                                                .foregroundColor(SensorIconConstants.customColor)
                                                .opacity(0.7)
                                                .shadow(color: .pink, radius: 2)
                                                .scaleEffect(bgScaleFactor)
                                            
                                            if(SensorIconConstants.sensorVisual[i].name.contains("eye")){
                                                Image(systemName: "eye")
                                                    .renderingMode(.template)
                                                    .foregroundColor(SensorIconConstants.customColor)
                                                    .scaleEffect(bgScaleFactor)
                                            }
                                            
                                            VStack{
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
                                                
                                                Text(SensorIconConstants.sensorVisual[i].name)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color.white)
                                                    .font(.system(size: fontSize) .weight(.heavy))
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .shadow(
                                                        color:.black,
                                                        radius:10)
                                            }
                                        }
                                        .scaleEffect(scaleFactor)
                                        
                                    }
                                    
                                }
                            }
                        }
                        
                    }

                    if isClickedNoise{
                        withAnimation{
                            VStack (alignment: .leading) {
    //                            Text("Noise")
    //                                .font(.system(size: 22) .weight(.heavy))
    //                                .padding(.trailing)
                                LazyVGrid(columns: columns, spacing: 1) {
                                    ForEach(0..<SensorIconConstants.sensorAcoustics.count){i in
//                                        let dummyValue = Double.random(in: 50.0 ..< 80.0)
                                        ZStack{
                                            Image(acousticsBgImageAssets[i])
                                                .renderingMode(.template)
                                                .foregroundColor(SensorIconConstants.customColor)
                                                .opacity(0.7)
                                                .shadow(color: .pink, radius: 2)
                                                .scaleEffect(bgScaleFactor)
                                            
                                            VStack{
                                                OpenCircularGauge(
                                                    current: receiver.acoutsticsData[i],//dummyValue,
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
                                                
                                                Text(SensorIconConstants.sensorAcoustics[i].name)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color.white)
                                                    .font(.system(size: fontSize) .weight(.heavy))
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .shadow(
                                                        color:.black,
                                                        radius:10)
                                            }
                                            
                                        }
                                        .scaleEffect(scaleFactor)
                                        
                                    }
                                }
                            }
                        }
                    }

                }
                    
                
            }
            .navigationTitle("Home")
        }

        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                isClickedThermal = false
                isClickedAirQuality = false
                isClickedVisual = false
                isClickedNoise = false
                /// get user's comfort range
                color1PositionThermal = [UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
                color3PositionThermal = [UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
                
                color1PositionVisual = [UserDefaults.standard.double(forKey: "minValueLightIntensity"),UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
                color3PositionVisual = [UserDefaults.standard.double(forKey: "maxValueLightIntensity"),UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
                
                color1PositionAcoutstics = [UserDefaults.standard.double(forKey: "minValueNoise"), UserDefaults.standard.double(forKey: "minValueNoise")]
                color3PositionAcoutstics = [UserDefaults.standard.double(forKey: "maxValueNoise"), UserDefaults.standard.double(forKey: "maxValueNoise")]


            }else{
            }
        }

        .onAppear{
            isClickedThermal = false
            isClickedAirQuality = false
            isClickedVisual = false
            isClickedNoise = false
            print("iOS Home Active")
            
            /// get user's comfort range
            color1PositionThermal = [UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
            color3PositionThermal = [UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
            
            color1PositionVisual = [UserDefaults.standard.double(forKey: "minValueLightIntensity"),UserDefaults.standard.double(forKey: "minValueTemp"), UserDefaults.standard.double(forKey: "minValueHum")]
            color3PositionVisual = [UserDefaults.standard.double(forKey: "maxValueLightIntensity"),UserDefaults.standard.double(forKey: "maxValueTemp"), UserDefaults.standard.double(forKey: "maxValueHum")]
            
            color1PositionAcoutstics = [UserDefaults.standard.double(forKey: "minValueNoise"), UserDefaults.standard.double(forKey: "minValueNoise")]
            color3PositionAcoutstics = [UserDefaults.standard.double(forKey: "maxValueNoise"), UserDefaults.standard.double(forKey: "maxValueNoise")]



        }

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

