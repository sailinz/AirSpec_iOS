//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.02.23.
//

import Foundation
import CoreData

class RawDataViewModel: ObservableObject{
    let container: NSPersistentContainer
    @Published var savedEntities: [RawDataEntity] = []
    
    init(){
        // load core data
        container = NSPersistentContainer(name: "RawDataContainer")
        container.loadPersistentStores{(description, error) in
            if let error = error{
                print("ERROR LOADING CORE DATA. \(error)")
            }else {
                print("Successfully loaded core data for RawDataContainer!")
            }
        }
        fetchRawData()
    }
    
    func fetchRawData(){
        let request = NSFetchRequest<RawDataEntity>(entityName: "RawDataEntity")
        do{
            savedEntities = try container.viewContext.fetch(request)
        }catch let error{
            print("Error fetching. \(error)")
        }
        
    }
    
    
    
    func addRawData(record: Data){
        let newRawData = RawDataEntity(context: container.viewContext)
        
        newRawData.record = record
        
        saveData()
    }
    
    func deleteRawData(batchSize: Int){
        for i in 0..<batchSize{
            guard let entity = savedEntities.first else { return }
            container.viewContext.delete(entity)
        }
        
    }
    
    func saveData() {
        do{
            try container.viewContext.save()
            fetchRawData()
//            print("Saved raw data to core data")
        }catch{
            print("Error saving. \(error)")
        }
    }
    
}
     

