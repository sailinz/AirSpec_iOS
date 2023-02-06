//
//  ProgramObject.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.02.23.
//  https://www.youtube.com/watch?v=i3_6m0a5ovw&t=3407s

import Foundation
import UIKit

/// for watchconnectivity
public class ProgramObject: NSObject, ObservableObject, NSSecureCoding{
    
    public static var supportsSecureCoding: Bool = true
//    @Published var thermalData = Array(repeating: -1.0, count: SensorIconConstants.sensorThermal.count)
//    @Published var airQualityData = Array(repeating: -1.0, count: SensorIconConstants.sensorAirQuality.count)
//    @Published var visualData = Array(repeating: -1.0, count: SensorIconConstants.sensorVisual.count)
//    @Published var acoutsticsData = Array(repeating: -1.0, count: SensorIconConstants.sensorAcoustics.count)
    
    @Published var co2 : String?
    @Published var iaq : String?
    @Published var lux : String?
    @Published var temperature : String?
    @Published var humidity : String?
    @Published var vocIndexValue : String?
    @Published var noxIndexValue : String?
    
    func initWithData(co2 : String,
                      iaq: String,
                      lux: String,
                      temperature: String,
                      humidity: String,
                      vocIndexValue: String,
                      noxIndexValue: String
    ){
        self.co2 = co2
        self.iaq = iaq
        self.lux = lux
        self.temperature = temperature
        self.humidity = humidity
        self.vocIndexValue = vocIndexValue
        self.noxIndexValue = noxIndexValue
    }
    
    public required convenience init?(coder: NSCoder) {
        guard let co2 = coder.decodeObject(forKey: "co2") as? String,
              let iaq = coder.decodeObject(forKey: "iaq") as? String,
              let lux = coder.decodeObject(forKey: "lux") as? String,
              let temperature = coder.decodeObject(forKey: "temperature") as? String,
              let humidity = coder.decodeObject(forKey: "humidity") as? String,
              let vocIndexValue = coder.decodeObject(forKey: "vocIndexValue") as? String,
              let noxIndexValue = coder.decodeObject(forKey: "noxIndexValue") as? String
        else {return nil}
        self.init()
        self.initWithData(co2: co2 as String,
                          iaq: iaq as String,
                          lux: lux as String,
                          temperature: temperature as String,
                          humidity: humidity as String,
                          vocIndexValue: vocIndexValue as String,
                          noxIndexValue: noxIndexValue as String
        
        )
              
              
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.co2, forKey: "co2")
        coder.encode(self.iaq, forKey: "iaq")
        coder.encode(self.lux, forKey: "lux")
        coder.encode(self.temperature, forKey: "temperature")
        coder.encode(self.humidity, forKey: "humidity")
        coder.encode(self.vocIndexValue, forKey: "vocIndexValue")
        coder.encode(self.noxIndexValue, forKey: "noxIndexValue")
    }
    
    
    
    
    
    
    
    
}
