/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Bluetooth identifiers to use throughout the project.
*/

import CoreBluetooth

enum BluetoothConstants {
    
//    /// An identifier for the sample service.
//    static let sampleServiceUUID = CBUUID(string: "0000fe80-8e22-4541-9d4c-21edae82ed19")
//
//    /// An identifier for the sample characteristic.
//    static let sampleCharacteristicUUID = CBUUID(string: "0000FE81-8E22-4541-9D4C-21EDAE82ED19")
    
    /// An identifier for the AirSpec service.
    static let airspecServiceUUID = CBUUID(string: "0000fe80-0000-1000-8000-00805f9b34fb") /// short FE80
    
    /// An identifier for the characteristic for read data from AirSpec.
    static let airspecTXCharacteristicUUID = CBUUID(string: "0000fe81-0000-1000-8000-00805f9b34fb") /// short FE81
    
    /// An identifier for the characteristic for read data from AirSpec.
    static let airspecRXCharacteristicUUID = CBUUID(string: "0000fe82-0000-1000-8000-00805f9b34fb")


    /// The defaults key to use for persisting the most recently received data.
    static let receivedDataKey = "received-data"
    
    /// The maximum normal temperature, above which the app displays an alert.
//    static let normalTemperatureLimit = 45
}


