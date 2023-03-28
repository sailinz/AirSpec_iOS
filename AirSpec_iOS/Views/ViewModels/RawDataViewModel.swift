//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin and Nathan PERRY on 14.02.23.
//

import Foundation
import CoreData
import os.log

class RawDataViewModel {
    static let container: NSPersistentContainer = NSPersistentContainer(name: "RawDataContainer")
    static let log_container: NSPersistentContainer = NSPersistentContainer(name: "logs")
    static let MAX_UNSENT_COUNT = 40960 ///1 hour
    static let DELETE_CHUNK = MAX_UNSENT_COUNT / 10
    static let MAX_HIGH_FREQUENCY_PROP = 0.5
    
    static let q = DispatchQueue(label: "init_rawdata")
    static var has_init = false
    
    private static let logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: RawDataViewModel.self)
    )

    static func init_container() {
        q.sync {
            if has_init {
                return
            }

            // load core data
            var err: Error?
            
            for cont in [container, log_container] {
                cont.loadPersistentStores{(description, error) in
                    if let error = error {
                        err = error
                        RawDataViewModel.addMetaDataLogToRawData(payload: "raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
                    }
                }
            }
            
            if let error = err {
                print("initializing container: \(error)")
            } else {
                has_init = true
            }
        }
    }
    
    static func shouldDisableHighFrequency() throws -> Bool {
        return try Self.count() > Int(Double(MAX_UNSENT_COUNT) * MAX_HIGH_FREQUENCY_PROP)
    }

    static func count() throws -> Int {
        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")

        let ctx = container.viewContext
        var ret: Int?
        var err: Error?
        
        ctx.performAndWait {
            do {
                ret = try ctx.count(for: request)
            } catch {
                err = error
                RawDataViewModel.addMetaDataLogToRawData(payload: "raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
            }
        }

        if let e = err {
            throw e
        }

        return ret!
    }
    
    static func fetchData(_ n: Int = 10) throws -> ([SensorPacket], () throws -> Void) {
        let (sensor_data, sensor_cleanup) = try fetchData(n, fromContainer: container)
        let (log_data, log_cleanup) = try fetchData(n - sensor_data.count, fromContainer: log_container)
//        logger.info("log container count: \(log_data.count)")
        
        return (sensor_data + log_data, {
            try sensor_cleanup()
            try log_cleanup()
        })
    }

    static func fetchData(_ n: Int = 10, fromContainer container: NSPersistentContainer) throws -> ([SensorPacket], () throws -> Void) {
        if n == 0 {
            return ([], {})
        }
        
        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")
        request.fetchLimit = n

        let ctx = container.viewContext
        var ret: [SensorPacket] = []
        var err: Error?
        var ids: [NSManagedObjectID] = []

        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        ctx.performAndWait {
            do {
                let elems = try ctx.fetch(request)

                ret = try elems.map { ent in
                    ids.append(ent.objectID)
                    return try SensorPacket(serializedData: ent.record!)
                }

                try ctx.save()
            } catch {
                err = error
                RawDataViewModel.addMetaDataLogToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
            }
        }

        if let e = err {
            throw e
        }

        return (ret, {
            if ids.isEmpty {
                return
            }

            var err: Error?
            let del_req = NSBatchDeleteRequest(objectIDs: ids)

            ctx.performAndWait {
                do {
                    try ctx.execute(del_req)
                    try ctx.save()
                } catch {
                    err = error
                    RawDataViewModel.addMetaDataLogToRawData(payload: "Raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
                }
            }

            if let e = err {
                throw e
            }
        })
    }
    
    static func addMetaDataToRawData(payload: String, timestampUnix: Date, type: Int32){
//        logger.debug("add user/sensor metadata")
        
        var metaData = appMetaDataPacket()
        metaData.payload = payload
        metaData.timestampUnix = UInt64(timestampUnix.timeIntervalSince1970) * 1000
        metaData.type = UInt32(type)

        let sensorPacket = SensorPacket.with {
            $0.header = SensorPacketHeader.with {
                $0.epoch = UInt64(NSDate().timeIntervalSince1970 * 1000)
            }
            $0.metaDataPacket = metaData
        }


        do {
            let metaDataBinary = try sensorPacket.serializedData()
            try self.addRawData(record: metaDataBinary)
        } catch {
            print("fail to append user/sensor metadata:  \(error.localizedDescription)")
        }
    }


    static func addMetaDataLogToRawData(payload: String, timestampUnix: Date, type: Int32){
//        logger.debug("add core data raw data metadata")
        var metaData = appMetaDataPacket()
        metaData.payload = payload
        metaData.timestampUnix = UInt64(timestampUnix.timeIntervalSince1970) * 1000
        metaData.type = UInt32(type)

        let sensorPacket = SensorPacket.with {
            $0.header = SensorPacketHeader.with {
                $0.epoch = UInt64(NSDate().timeIntervalSince1970 * 1000)
            }

            $0.metaDataPacket = metaData
        }

        do {
            let metaDataBinary = try sensorPacket.serializedData()
            try saveData(metaDataBinary, toContainer: log_container, saveErrors: false)
        } catch {
            print("fail to append core data raw data metadata:  \(error.localizedDescription)")
        }
    }

    static func addSurveyDataToRawData(qIndex: Int32, qChoice: String, qGroupIndex: UInt32, timestampUnix: Date){
//        logger.debug("add survey data")
        
        var surveyData = appSurveyDataPacket()
        surveyData.payload = [appSurveyDataPayload()]
        surveyData.payload[0].qIndex = qIndex
        surveyData.payload[0].qChoice = qChoice
        surveyData.payload[0].qGroupIndex = qGroupIndex
        surveyData.payload[0].timestampUnix = UInt64(timestampUnix.timeIntervalSince1970) * 1000

        let sensorPacket = SensorPacket.with {
            $0.header = SensorPacketHeader.with {
                $0.epoch = UInt64(NSDate().timeIntervalSince1970 * 1000)
            }

            $0.surveyPacket = surveyData
        }

        do {
            let surveyDataBinary = try sensorPacket.serializedData()
            try self.addRawData(record: surveyDataBinary)
            print(surveyData)
        } catch {
            print("Fail to append survey data to raw data:  \(error.localizedDescription)")
        }
    }
    
    static func saveData(_ record: Data, toContainer container: NSPersistentContainer, saveErrors: Bool) throws {
        let newRawData = RawDataEntity(context: container.viewContext)
        newRawData.record = record

        let ctx = container.viewContext
        var err: Error?

        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")

        ctx.performAndWait {
            do {
                let count = try ctx.count(for: request)

                if count >= MAX_UNSENT_COUNT {
                    let log_str = "too many stored records, cleaning up (have: \(count), max: \(MAX_UNSENT_COUNT))"
                    
                    logger.warning("\(log_str)")

                    let delete_old = NSFetchRequest<NSFetchRequestResult>(entityName: "RawDataEntity")
                    delete_old.fetchLimit = (count - MAX_UNSENT_COUNT + DELETE_CHUNK)
                    
                    if saveErrors {
                        addMetaDataLogToRawData(payload: log_str, timestampUnix: Date(), type: 2)
                    }
                    
                    let del_req = NSBatchDeleteRequest(fetchRequest: delete_old)
                    try ctx.execute(del_req)
                }

                ctx.insert(newRawData)
                try ctx.save()
            } catch {
                err = error
            }
        }

        if let e = err {
            throw e
        }

    }

    static func addRawData(record: Data) throws {
        return try saveData(record, toContainer: container, saveErrors: true)
    }
}
