//
//  SensorIconConstants.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 16.12.22.

import Foundation
import SwiftUI

struct Icon  {
    /// UI
    let name:String
    let icon:String
    let color1:Color
    let color2:Color
    let color3:Color
    let minValue:Double
    let maxValue:Double
    var color1Position:Double
    var color3Position:Double
    
    /// influxdb
    let measurement:String
//    let field:String = "signal"
//    var id:String = "9067133"
    let type:String
    var identifier:String = "type"
    
}

enum SensorIconConstants {
    static let sensorThermal = [
        Icon(name: "Temperature  ", icon: "thermometer.medium", color1: Color.cyan, color2: Color.white, color3: Color.red, minValue: 15.0, maxValue: 35.0, color1Position:0.2, color3Position:0.8, measurement:"sht45", type:"temperature"),
        Icon(name: "Humidity        ", icon: "humidity", color1: Color.yellow, color2: Color.white, color3: Color.cyan, minValue: 0.0, maxValue: 100.0, color1Position:0.3, color3Position:0.7, measurement:"sht45", type:"humidity"),
//        Icon(name: "Air pressure  ", icon: "cloud.fog", color1: Color.white, color2: Color.red, color3: Color.red, minValue: 100000, maxValue: 102000, color1Position:0.2, color3Position:0.8, measurement:"bme", type:"7", identifier:"sensor_id"), /// both pressure and gas is sensor_id 7????
    ]
    
    static let sensorAirQuality = [
        Icon(name: "VOC index        ", icon: "wind", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 0.0, maxValue: 500.0, color1Position:0.3, color3Position:0.7, measurement:"sgp", type:"voc_index_value"),
        Icon(name: "NOx index        ", icon: "aqi.high", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 0, maxValue: 10.0, color1Position:0.1, color3Position:0.5, measurement:"sgp", type:"nox_index_value"),
        Icon(name: "CO2               ", icon: "carbon.dioxide.cloud", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 300.0, maxValue: 1500.0, color1Position:0.25, color3Position:0.58, measurement:"bme", type:"3", identifier:"sensor_id"),
        Icon(name: "IAQ               ", icon: "aqi.medium", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 0.0, maxValue: 400.0, color1Position:0.25, color3Position:0.5, measurement:"bme", type:"1", identifier:"sensor_id"),
//        Icon(name: "Gas               ", icon: "aqi.medium", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 100500, maxValue: 102000, color1Position:0.2, color3Position:0.8, measurement:"bme", type:"7", identifier:"sensor_id"),
    ]
    
    static let sensorVisual = [
        Icon(name: "Light Intensity", icon: "light.overhead.right", color1: Color.yellow, color2: Color.white, color3: Color.yellow, minValue: 0.0, maxValue: 1000.0, color1Position:0.1, color3Position:0.8, measurement:"lux",type:""),
    ]
    
    static let sensorAcoustics = [
        Icon(name: "Human Noise   ", icon: "ear", color1: Color.white, color2: Color.yellow, color3: Color.yellow, minValue: 0.0, maxValue: 150.0, color1Position:0.2, color3Position:0.8, measurement:"",type:""),
        Icon(name: "Ambient Noise ", icon: "ear.and.waveform", color1: Color.white, color2: Color.yellow, color3: Color.yellow, minValue: 0.0, maxValue: 150.0, color1Position:0.2, color3Position:0.8, measurement:"",type:""),
    ]
    
    
}
