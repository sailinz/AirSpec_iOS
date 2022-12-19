//
//  NetworkConstants.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 09.12.22.
//

enum NetworkConstants {
    
    /// server
//    static let host:String = "airspecs.media.mit.edu"
//    static let port:Int = 64235
    static let host:String = "airspecs.media.mit.edu"
    static let port:Int = 65434
    
    /// influxdb
    static let url:String = "http://airspecs.media.mit.edu:8086"
//    private var token:String = ProcessInfo.processInfo.environment["INFLUX_TOKEN"]!
    static let token:String = "VeGcVPwjl6IWc-B7vnyJZ9pwzUC4y8o71PdVI5h2UrndZtjKkOzmdBMxXJAssJfPtsCKNNyT9-MFdEL2mXHgaQ=="
    static let bucket:String = "airspec"
    static let org:String = "media_lab"

}
