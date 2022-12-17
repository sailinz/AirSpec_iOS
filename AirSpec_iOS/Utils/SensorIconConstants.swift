//
//  SensorIconConstants.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 16.12.22.

import Foundation
import SwiftUI

struct Icon  {
    let name:String
    let icon:String
    let color1:Color
    let color2:Color
    let color3:Color
}

enum SensorIconConstants {
    static let sensorThermal = [
        Icon(name: "Temperature  ", icon: "thermometer.medium", color1: Color.cyan, color2: Color.white, color3: Color.red),
        Icon(name: "Humidity        ", icon: "humidity", color1: Color.yellow, color2: Color.white, color3: Color.cyan),
        Icon(name: "Air pressure  ", icon: "cloud.fog", color1: Color.white, color2: Color.red, color3: Color.red),
    ]
    
    static let sensorAcoustics = [
        Icon(name: "Human Noise   ", icon: "ear", color1: Color.white, color2: Color.yellow, color3: Color.yellow),
        Icon(name: "Ambient Noise ", icon: "ear.and.waveform", color1: Color.white, color2: Color.yellow, color3: Color.yellow),
    ]
    
    static let sensorVisual = [
        Icon(name: "Light Intensity", icon: "light.overhead.right", color1: Color.white, color2: Color.yellow, color3: Color.white),
    ]
    
    static let sensorAirQuality = [
        Icon(name: "VOC               ", icon: "wind", color1: Color.mint, color2: Color.yellow, color3: Color.red),
        Icon(name: "NOx               ", icon: "wind", color1: Color.mint, color2: Color.yellow, color3: Color.red),
        Icon(name: "CO2               ", icon: "carbon.dioxide.cloud", color1: Color.mint, color2: Color.yellow, color3: Color.red),
        Icon(name: "IAQ               ", icon: "aqi.medium", color1: Color.mint, color2: Color.yellow, color3: Color.red),
        Icon(name: "Gas               ", icon: "aqi.medium", color1: Color.mint, color2: Color.yellow, color3: Color.red),
        
        
    ]
}
