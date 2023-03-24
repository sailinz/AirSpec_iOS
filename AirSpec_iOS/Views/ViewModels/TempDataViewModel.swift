//
//  File.swift
//  AirSpec_iOS
//
//  Created by  ZHONG Sailin and Nathan PERRY on 14.02.23.

import Foundation
import CoreData

class TempDataViewModel {
    static let container: NSPersistentContainer = NSPersistentContainer(name: "TempDataContainer")
    static let MAX_UNSENT_COUNT = 40960
    
    static let q = DispatchQueue(label: "init_TempData")
    static var has_init = false
    
    static func init_container() {
        q.sync {
            if has_init {
                return
            }
            
            // load core data
            var err: Error?
            
            container.loadPersistentStores{(description, error) in
                if let error = error {
                    err = error
                    RawDataViewModel.addMetaDataToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
                }
            }
            
            if let error = err {
                print("initializing container")
            } else {
                has_init = true
            }
        }
    }
    
    static func count() throws -> Int {
        let request = NSFetchRequest<TempDataEntity>(entityName: "TempDataEntity")

        let ctx = container.viewContext
        var ret: Int?
        var err: Error?
        
        ctx.performAndWait {
            do {
                ret = try ctx.count(for: request)
            } catch {
                err = error
                RawDataViewModel.addMetaDataToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
            }
        }
        
        if let e = err {
            throw e
        }
        
        return ret!
    }
    
    static func fetchData(_ n: Int = 10) throws -> ([(Date, String, Float)], () throws -> Void) {
        let request = NSFetchRequest<TempDataEntity>(entityName: "TempDataEntity")
                
        let ctx = container.viewContext
        var ret: [(Date, String, Float)] = []
        var err: Error?
        var ids: [NSManagedObjectID] = []
        
        ctx.performAndWait {
            do {
                let elems = try ctx.fetch(request)
                
                ret = try elems.map { ent in
                    ids.append(ent.objectID)
                    return try (ent.timestamp!, ent.sensor!, ent.value)
                }

                try ctx.save()
            } catch {
                err = error
                RawDataViewModel.addMetaDataToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
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
                    RawDataViewModel.addMetaDataToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
                }
            }

            if let e = err {
                throw e
            }

        })
    }
    
    
    static func addTempData(timestamp: Date, sensor: String, value: Float) throws {
        let newTempData = TempDataEntity(context: container.viewContext)
        newTempData.timestamp = timestamp
        newTempData.sensor = sensor
        newTempData.value = value
        
        let ctx = container.viewContext
        var err: Error?

        let request = NSFetchRequest<TempDataEntity>(entityName: "TempDataEntity")

        ctx.performAndWait {
            do {
                let count = try ctx.count(for: request)
                
                if count >= MAX_UNSENT_COUNT {
                    let delete_old = NSFetchRequest<NSFetchRequestResult>(entityName: "TempDataEntity")
                    delete_old.fetchLimit = 100
                    
                    let del_req = NSBatchDeleteRequest(fetchRequest: delete_old)
                    try ctx.execute(del_req)
                }
                
                ctx.insert(newTempData)
                try ctx.save()
            } catch {
                err = error
                RawDataViewModel.addMetaDataToRawData(payload: "temp data view model error \(String(describing: err))", timestampUnix: Date(), type: 2)
            }
        }
        
        if let e = err {
            throw e
        }
    }
}
     



