//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.02.23.
//

import Foundation
import CoreData

class MetaDataViewModel: ObservableObject{
    let container: NSPersistentContainer
    @Published var savedEntities: [MetaDataEntity] = []
    
    init(){
        // load core data
        container = NSPersistentContainer(name: "MetaDataContainer")
        container.loadPersistentStores{(description, error) in
            if let error = error{
                print("ERROR LOADING CORE DATA. \(error)")
            }else {
                print("Successfully loaded core data for MetaDataContainer!")
            }
        }
        fetchMetaData()
    }
    
    func fetchMetaData(){
        let request = NSFetchRequest<MetaDataEntity>(entityName: "MetaDataEntity")
        
        do{
            savedEntities = try container.viewContext.fetch(request)
        }catch let error{
            print("Error fetching. \(error)")
        }
        
    }
    
    func addMetaData(timestamp: Int32, name: String, userid: Int16){
        let newMetaData = MetaDataEntity(context: container.viewContext)
        
        newMetaData.timestamp = timestamp
        newMetaData.name = name
        newMetaData.userid = userid
        saveData()
    }
    
    func saveData() {
        do{
            try container.viewContext.save()
            fetchMetaData()
            print("Saved meta data to core data")
        }catch{
            print("Error saving. \(error)")
        }
    }
    
}
     

