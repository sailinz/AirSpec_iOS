///  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin and Nathan PERRY on 23.03.23.
//  just copy pasted the whole code from RawDataViewModel

import Foundation
import CoreData
import os.log

class TempRawDataViewModel {
    static let container: NSPersistentContainer = NSPersistentContainer(name: "TempRawDataContainer")
    static let log_container: NSPersistentContainer = NSPersistentContainer(name: "logs")
    static let MAX_UNSENT_COUNT = 40960 ///1 hour
    static let DELETE_CHUNK = MAX_UNSENT_COUNT / 10

    static let q = DispatchQueue(label: "init_TempRawData")
    static var has_init = false
    
    private static let logger = Logger(
        subsystem: AirSpec_iOSApp.name,
        category: String(describing: TempRawDataViewModel.self)
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
//                        TempRawDataViewModel.addMetaDataLogToTempRawData(payload: "raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
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

    static func count() throws -> Int {
        let request = NSFetchRequest<TempRawDataEntity>(entityName: "TempRawDataEntity")

        let ctx = container.viewContext
        var ret: Int?
        var err: Error?
        
        ctx.performAndWait {
            do {
                ret = try ctx.count(for: request)
            } catch {
                err = error
//                TempRawDataViewModel.addMetaDataLogToTempRawData(payload: "raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
            }
        }

        if let e = err {
            throw e
        }

        return ret!
    }
    


    static func fetchData(_ n: Int = 100) throws -> ([SensorPacket], () throws -> Void) {
        if n == 0 {
            return ([], {})
        }
        
        let request = NSFetchRequest<TempRawDataEntity>(entityName: "TempRawDataEntity")
        request.fetchLimit = n

        let ctx = container.viewContext
        var ret: [SensorPacket] = []
        var err: Error?
        var ids: [NSManagedObjectID] = []
        
        
        let newRawData = RawDataEntity(context: RawDataViewModel.container.viewContext)
        

        let ctxRawDataModel = RawDataViewModel.container.viewContext

        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        ctx.performAndWait {
            do {
                let elems = try ctx.fetch(request)

                ret = try elems.map { ent in
                    ids.append(ent.objectID)
                    newRawData.record = ent.record!
                    ctxRawDataModel.insert(newRawData)
//                    print(ids)
                    if ret.isEmpty{
                        return SensorPacket()
                    }else{
                        return ret[0]
                    }
                    
                }

                try ctx.save()
            } catch {
                err = error
//                TempRawDataViewModel.addMetaDataLogToTempRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
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
//                    TempRawDataViewModel.addMetaDataLogToTempRawData(payload: "Raw data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
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
            try self.addTempRawData(record: metaDataBinary)
        } catch {
            print("fail to append user/sensor metadata to temp raw data:  \(error.localizedDescription)")
        }
    }

    
    static func saveData(_ record: Data, toContainer container: NSPersistentContainer, saveErrors: Bool) throws {
        let newTempRawData = TempRawDataEntity(context: container.viewContext)
        newTempRawData.record = record

        let ctx = container.viewContext
        var err: Error?

        let request = NSFetchRequest<TempRawDataEntity>(entityName: "TempRawDataEntity")

        ctx.performAndWait {
            do {
                let count = try ctx.count(for: request)

                if count >= MAX_UNSENT_COUNT {
                    let log_str = "too many stored records, cleaning up (have: \(count), max: \(MAX_UNSENT_COUNT))"
                    
                    logger.warning("\(log_str)")

                    let delete_old = NSFetchRequest<NSFetchRequestResult>(entityName: "TempRawDataEntity")
                    delete_old.fetchLimit = (count - MAX_UNSENT_COUNT + DELETE_CHUNK)
                    
//                    if saveErrors {
//                        addMetaDataLogToTempRawData(payload: log_str, timestampUnix: Date(), type: 2)
//                    }
                    
                    let del_req = NSBatchDeleteRequest(fetchRequest: delete_old)
                    try ctx.execute(del_req)
                }

                ctx.insert(newTempRawData)
                try ctx.save()
            } catch {
                err = error
            }
        }

        if let e = err {
            throw e
        }

    }

    static func addTempRawData(record: Data) throws {
        return try saveData(record, toContainer: container, saveErrors: true)
    }
}


