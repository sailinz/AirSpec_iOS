//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.02.23.
//

import Foundation
import CoreData

class TempDataViewModel: ObservableObject{
    let container: NSPersistentContainer
    @Published var savedEntities: [TempDataEntity] = []
    
    init(){
        // load core data
        container = NSPersistentContainer(name: "TempDataContainer")
        container.loadPersistentStores{(description, error) in
            if let error = error{
                print("ERROR LOADING CORE DATA. \(error)")
            }else {
                print("Successfully loaded core data for TempDataContainer!")
            }
        }
        fetchTempData()
    }
    
    func fetchTempData(){
        let request = NSFetchRequest<TempDataEntity>(entityName: "TempDataEntity")
        
        do{
            savedEntities = try container.viewContext.fetch(request)
        }catch let error{
            print("Error fetching. \(error)")
        }
        
    }
    
    func addTempData(timestamp: Int32, sensor: String, value: Float){
        let newTempData = TempDataEntity(context: container.viewContext)
        
        newTempData.timestamp = timestamp
        newTempData.sensor = sensor
        newTempData.value = value
        
        saveData()
    }
    
    func saveData() {
        do{
            try container.viewContext.save()
            fetchTempData()
            print("Saved temporary data to core data")
        }catch{
            print("Error saving. \(error)")
        }
    }
    
}
     

