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
    /// An identifier for the characteristic for write data to the AirSpec.
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
    
    
    static let glassesNames = ["_000000", "AirSpec_01ad6f6b", "AirSpec_01ad7855", "AirSpec_01ad71de", "AirSpec_01ad7052", "AirSpec_01ad72c2", "AirSpec_01ad7040","AirSpec_01ad6d72","AirSpec_01ad6cff","AirSpec_01ad6ce3","AirSpec_01ad6e53","AirSpec_01ad743c","AirSpec_01ad7677","AirSpec_01ad6e65","AirSpec_01ad0014","AirSpec_01ad6fa1", "AirSpec_01ad7ae6","AirSpec_01ad71bf","AirSpec_01ad7859" ] /// now glasses 2 is for development, glasses 1 is for testing
    
    
    /// The maximum normal temperature, above which the app displays an alert.
//    static let normalTemperatureLimit = 45
}


