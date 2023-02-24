//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin and Nathan PERRY on 14.02.23.
//

import Foundation
import CoreData

class RawDataViewModel {
    static let container: NSPersistentContainer = NSPersistentContainer(name: "RawDataContainer")
    static let MAX_UNSENT_COUNT = 4096
    
    static let q = DispatchQueue(label: "init_rawdata")
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
        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")

        let ctx = container.viewContext
        var ret: Int?
        var err: Error?
        
        ctx.performAndWait {
            do {
                ret = try ctx.count(for: request)
            } catch {
                err = error
            }
        }
        
        if let e = err {
            throw e
        }
        
        return ret!
    }
    
    static func fetchData(_ n: Int = 100) throws -> ([SensorPacket], () throws -> Void) {
        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")
        request.fetchLimit = n
                
        let ctx = container.viewContext
        var ret: [SensorPacket] = []
        var err: Error?
        var ids: [NSManagedObjectID] = []
        
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
                }
            }
            
            if let e = err {
                throw e
            }
        })
    }
    
    
    static func addRawData(record: Data) throws {
        let newRawData = RawDataEntity(context: container.viewContext)
        newRawData.record = record
        
        let ctx = container.viewContext
        var err: Error?

        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")

        ctx.performAndWait {
            do {
                let count = try ctx.count(for: request)
                
                if count >= MAX_UNSENT_COUNT {
                    let delete_old = NSFetchRequest<NSFetchRequestResult>(entityName: "RawDataEntity")
                    delete_old.fetchLimit = 100
                    
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
}
     

