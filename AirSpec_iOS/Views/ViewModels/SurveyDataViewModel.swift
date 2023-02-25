//
//  File.swift
//  AirSpec_iOS
//
//  Created by  ZHONG Sailin, Nathan PERRY on 14.02.23.

import Foundation
import CoreData

class SurveyDataViewModel {
    static let container: NSPersistentContainer = NSPersistentContainer(name: "SurveyDataContainer")
    static let MAX_UNSENT_COUNT = 4096 * 3
    
    static let q = DispatchQueue(label: "init_surveydata")
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
        let request = NSFetchRequest<SurveyDataEntity>(entityName: "SurveyDataEntity")

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
    
    static func fetchData() throws -> ([(Date, Int16, String)], () throws -> Void) {
        let request = NSFetchRequest<SurveyDataEntity>(entityName: "SurveyDataEntity")
                
        let ctx = container.viewContext
        var ret: [(Date, Int16, String)] = []
        var err: Error?
        var ids: [NSManagedObjectID] = []
        
        ctx.performAndWait {
            do {
                let elems = try ctx.fetch(request)
                
                ret = try elems.map { ent in
                    ids.append(ent.objectID)
                    return try (ent.timestamp!, ent.question, ent.choice!)
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

        })
    }
    
    
    static func addSurveyData(timestamp: Date, question: Int16, choice: String) throws {
        let newSurveyData = SurveyDataEntity(context: container.viewContext)
        newSurveyData.timestamp = timestamp
        newSurveyData.question = question
        newSurveyData.choice = choice
        
        
        let ctx = container.viewContext
        var err: Error?

        let request = NSFetchRequest<SurveyDataEntity>(entityName: "SurveyDataEntity")

        ctx.performAndWait {
            do {
                let count = try ctx.count(for: request)
                
                if count >= MAX_UNSENT_COUNT {
                    let delete_old = NSFetchRequest<NSFetchRequestResult>(entityName: "SurveyDataEntity")
                    delete_old.fetchLimit = 100
                    
                    let del_req = NSBatchDeleteRequest(fetchRequest: delete_old)
                    try ctx.execute(del_req)
                }
                
                ctx.insert(newSurveyData)
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
     



