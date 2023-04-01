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
    let unit:String
    
    /// influxdb
    let measurement:String
    let type:String
    var identifier:String = "type"
    
    /// daily data
    var meaning:String = ""
    

}

enum SensorIconConstants {
    static let sensorThermal = [
        Icon(name: "Temperature\n", icon: "thermometer.medium", color1: Color.cyan, color2: Color.white, color3: Color.red, minValue: 10.0, maxValue: 35.0, color1Position:0.2, color3Position:0.8, unit:"°C", measurement:"sht45", type:"temperature", meaning: "Ambient temperature is measured with the accessory sensor node on the side of the glasses. The blue-red color-coded cold and warm range can be defined by you in the settings. Your interaction with these settings will help AirSpecs to have your personalized thermal comfort model in the future."),
        Icon(name: "Humidity\n", icon: "humidity", color1: Color.yellow, color2: Color.white, color3: Color.cyan, minValue: 0.0, maxValue: 100.0, color1Position:0.3, color3Position:0.7, unit:"%", measurement:"sht45", type:"humidity", meaning: "Ambient humidity is measured with the accessory sensor node on the side of the glasses. The yellow-blue color-coded dry and wet range can be defined by you in the settings. Your interaction with these settings will help AirSpecs to have your personalized thermal comfort model in the future."),
//        Icon(name: "Air pressure  ", icon: "cloud.fog", color1: Color.white, color2: Color.red, color3: Color.red, minValue: 100000, maxValue: 102000, color1Position:0.2, color3Position:0.8, measurement:"bme", type:"7", identifier:"sensor_id"), /// both pressure and gas is sensor_id 7????
    ]
    
    static let sensorAirQuality = [
        Icon(name: "VOC\n", icon: "aqi.medium", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 0.0, maxValue: 500.0, color1Position:0.3, color3Position:0.7, unit: "", measurement:"sgp", type:"voc_index_value", meaning: "Volatile organic compounds (VOCs) index here indicates the the amount of chemicals that my have adverse healrth efforts on you in the air (like cleaning supplies, paints, and pesticides). Around or below 100 is generally a safe range. The higher number, the higher pollutant levels (color coded in yellow-red). This VOCs index is measured with the accessory sensor node on the side of the glasses, indicating the condition of your ambient environment."),
        Icon(name: "NOx\n", icon: "aqi.high", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 0, maxValue: 10.0, color1Position:0.1, color3Position:0.5, unit: "", measurement:"sgp", type:"nox_index_value", meaning: "Nitrogen Dioxide (NOx) index here indicates the the amount of toxic gases that my have adverse healrth efforts on you in the air (like gas stoves, tabacco smoke, emission from vehicles that run on gasoline). Around or below 1 is generally a safe range. The higher number, the higher pollutant levels (color coded in yellow-red). This NOx index is measured with the accessory sensor node on the side of the glasses, indicating the condition of your ambient environment."),
        Icon(name: "CO2\n(nose)", icon: "carbon.dioxide.cloud", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 300.0, maxValue: 1500.0, color1Position:0.25, color3Position:0.58, unit: "", measurement:"bme", type:"3", identifier:"sensor_id", meaning: "The equivalent CO2 here indicates the CO2 level around your face. Below 600 shows a good condition for your well-being. Higher CO2 (color coded in yellow-red) concentrations can have negative impact on your overall well-being, health, and cognitive skills. Increase ventilation with clean air is recommanded in such situations. This equivalent CO2 is measured on the nose bridge of the glasses, indicating the condition of your own inhalation of the air."),
        Icon(name: "VOC\n(nose)", icon: "aqi.medium", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 0.0, maxValue: 500.0, color1Position:0.3, color3Position:0.7, unit: "", measurement:"sgp", type:"voc_index_value", meaning: "Volatile organic compounds (VOCs) index here indicates the the amount of chemicals that my have adverse healrth efforts on you in the air (like cleaning supplies, paints, and pesticides). Around or below 100 is generally a safe range. The higher number, the high pollutant levels (color coded in yellow-red). This VOCs index is measured on the nose bridge of the glasses, indicating the condition of your own inhalation of the air."),
        Icon(name: "NOx\n(nose)", icon: "aqi.high", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 0, maxValue: 10.0, color1Position:0.1, color3Position:0.5, unit: "", measurement:"sgp", type:"nox_index_value", meaning: "Nitrogen Dioxide (NOx) index here indicates the the amount of toxic gases that my have adverse healrth efforts on you in the air (like gas stoves, tabacco smoke, emission from vehicles that run on gasoline). Around or below 1 is generally a safe range. The higher number, the higher pollutant levels (color coded in yellow-red). This NOx index is measured on the nose bridge of the glasses, indicating the condition of your own inhalation of the air."),
        Icon(name: "IAQ\n(nose)", icon: "wind", color1: Color.white, color2: Color.yellow, color3: Color.red, minValue: 0.0, maxValue: 400.0, color1Position:0.25, color3Position:0.5, unit: "", measurement:"bme", type:"1", identifier:"sensor_id", meaning: "IAQ index here indicates the overall indoor air quality around your face. Below 100 shows a good condition for your well-being. 100 - 200 indicates possibility or irratation and beyond 200 indicates possibility of severe health issue (color coded in yellow-red). Increase ventilation with clean air is recommanded in such situations. This IAQ index is measured on the nose bridge of the glasses, indicating the condition of your own inhalation of the air."),
//        Icon(name: "Gas               ", icon: "aqi.medium", color1: Color.mint, color2: Color.yellow, color3: Color.red, minValue: 100500, maxValue: 102000, color1Position:0.2, color3Position:0.8, measurement:"bme", type:"7", identifier:"sensor_id"),
        
    ]
    
    static let sensorVisual = [
        Icon(name: "Illuminance\n(eye)", icon: "light.overhead.right", color1: Color.yellow, color2: Color.white, color3: Color.yellow, minValue: 1.0, maxValue: 1000.0, color1Position:0.2, color3Position:0.8, unit: "lux", measurement:"lux",type:"", meaning: "The illuminance around your eye is measured on the nose bridge of the glasses. It shows the visible light present in your area. Normally office lighting is 200 - 500 lux but normally measured on the desk. The measurement directly at your eye level is generally has a lower value, so it's up to you to define the range that you feel comfortable with. The yellow-white-yellow color-coded range can be defined by you in the settings, indicating too little or too much light. Your interaction with these settings will help AirSpecs to have your personalized visual comfort model in the future."),
        Icon(name: "Temperature\n(eye)", icon: "thermometer.medium", color1: Color.cyan, color2: Color.white, color3: Color.red, minValue: 10.0, maxValue: 35.0, color1Position:0.2, color3Position:0.8, unit:"°C", measurement:"sht45", type:"temperature", meaning: "Temperature around your eye is measured on the nose bridge of the glasses. The blue-red color-coded cold and warm range is synced with range of ambient temperature defined by you in the settings. Your interaction with these settings will help AirSpecs to have your personalized visual comfort model in the future."),
        Icon(name: "Humidity\n(eye)", icon: "humidity", color1: Color.yellow, color2: Color.white, color3: Color.cyan, minValue: 0.0, maxValue: 100.0, color1Position:0.3, color3Position:0.7, unit:"%", measurement:"sht45", type:"humidity", meaning: "Humidity around your eye is measured on the nose bridge of the glasses. The yellow-blue color-coded dry and wet range is synced with range of ambient humidity defined by you in the settings. Your interaction with these settings will help AirSpecs to have your personalized visual comfort model in the future.")
    ]
    
    static let sensorAcoustics = [
        Icon(name: "Noise dBA\n", icon: "ear", color1: Color.yellow, color2: Color.white, color3: Color.yellow, minValue: 0.0, maxValue: 150.0, color1Position:0.2, color3Position:0.8, unit:"dBA", measurement:"",type:"", meaning:"The noise level is measured on the leg of the glasses. Below 80 dB is a good level of noise that will not affect your hearing. Otherwise, repeated, long-term exposure to a higher sound level may cause hearing damage. In addition, one's preferences of quiteness of the environment is very personal. The yellow-white-yellow color-coded range can be defined by you in the settings, indicating too little or too much ambient sound. Your interaction with these settings will help AirSpecs to have your personalized acoustic comfort model in the future."),
//        Icon(name: "FFT", icon: "ear.and.waveform", color1: Color.yellow, color2: Color.white, color3: Color.yellow, minValue: 0.0, maxValue: 150.0, color1Position:0.2, color3Position:0.8, unit: "dBA", measurement:"",type:""),
    ]
    
    static let goodStateOpacity = 0.7
    static let badStateOpacity = 0.3
    static let customColor = Color(red: 153/255, green: 81/255, blue: 111/255)
}

