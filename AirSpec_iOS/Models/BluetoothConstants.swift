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
    
    
    
//    /// An identifier for the AirSpec service.
//    static let airspecServiceUUID = CBUUID(string: "0000fe80-8e22-4541-9d4c-21edae82ed19") /// captivates service
//
//    /// An identifier for the characteristic for read data from AirSpec.
//    static let airspecTXCharacteristicUUID = CBUUID(string: "0000FE81-8E22-4541-9D4C-21EDAE82ED19") /// captivates read
//
//    /// An identifier for the characteristic for write data from AirSpec.
//    static let airspecRXCharacteristicUUID = CBUUID(string: "0000fe84-8e22-4541-9d4c-21edae82ed19") /// captivates write

    
    
    
    /// An identifier for the AirSpec service.
    static let airspecServiceUUID = CBUUID(string: "0000fe80-0000-1000-8000-00805f9b34fb") /// short FE80

    /// An identifier for the characteristic for read data from AirSpec.
    static let airspecTXCharacteristicUUID = CBUUID(string: "0000fe81-0000-1000-8000-00805f9b34fb") /// short FE81
    /// An identifier for the characteristic for write data from AirSpec.
    static let airspecRXCharacteristicUUID = CBUUID(string: "0000fe82-0000-1000-8000-00805f9b34fb")
    
    
    /// directly assign UUID of 10 users - this should be the same so no need but the name will be different
//    static let airspecServiceUUIDs = [CBUUID(string: "0000fe80-0000-1000-8000-00805f9b34fb")]
//    static let airspecTXCharacteristicUUIDs = [CBUUID(string: "0000fe81-0000-1000-8000-00805f9b34fb")]
//    static let airspecRXCharacteristicUUIDs = [CBUUID(string: "0000fe82-0000-1000-8000-00805f9b34fb")]
    static let influx_user_ids = ["9067133"]
    
    
    
//    /// An identifier for the AirSpec service.
//    static let airspecServiceUUID = CBUUID(string: "180D") /// short FE80
//
//    /// An identifier for the characteristic for read data from AirSpec.
//    static let airspecTXCharacteristicUUID = CBUUID(string: "2A38") /// short FE81
//
//    /// An identifier for the characteristic for write data from AirSpec.
//    static let airspecRXCharacteristicUUID = CBUUID(string: "2A39")


    /// The defaults key to use for persisting the most recently received data.
    static let receivedDataKey = "received-data"
    
    /// The maximum normal temperature, above which the app displays an alert.
//    static let normalTemperatureLimit = 45
}


