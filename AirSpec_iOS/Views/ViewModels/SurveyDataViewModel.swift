//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.02.23.
//

import Foundation
import CoreData

class SurveyDataViewModel: ObservableObject{
    let container: NSPersistentContainer
    @Published var savedEntities: [SurveyDataEntity] = []
    
    init(){
        // load core data
        container = NSPersistentContainer(name: "SurveyDataContainer")
        container.loadPersistentStores{(description, error) in
            if let error = error{
                print("ERROR LOADING CORE DATA. \(error)")
            }else {
                print("Successfully loaded core data for SurveyDataContainer!")
            }
        }
        fetchSurveyData()
    }
    
    func fetchSurveyData(){
        let request = NSFetchRequest<SurveyDataEntity>(entityName: "SurveyDataEntity")
        
        do{
            savedEntities = try container.viewContext.fetch(request)
        }catch let error{
            print("Error fetching. \(error)")
        }
        
    }
    
    func addSurveyData(timestamp: Int32, question: Int16, choice: String, userid: Int16){
        let newSurveyData = SurveyDataEntity(context: container.viewContext)
        
        newSurveyData.timestamp = timestamp
        newSurveyData.question = question
        newSurveyData.choice = choice
        newSurveyData.userid = userid
        
        saveData()
    }
    
    func saveData() {
        do{
            try container.viewContext.save()
            fetchSurveyData()
            print("Saved survey data to core data")
        }catch{
            print("Error saving. \(error)")
        }
    }
    
}
     